(in-package :geomyid)

(defvar *gopher-root*)
(defvar *host*)
(defvar *port*)

(defun write-html-redirect (stream url)
  (format stream "<html>
<head>
<meta http-equiv=\"refresh\" content=\"5; url=~A\">
</head>
<body>
<p>
The directory entry you selected was supposed to link to an HTTP-based
website. Unfortunately, your gopher client is pathetic and doesn't
support the hURL specification, so I've had to insert this shitty page
into my Gopher server. I hope you're happy.
</p>
<p>
If you're not redirected after 5 seconds of this loveliness, click the
below link to the URL you tried (and failed) to access.
</p>
<p>
The place you're supposed to be is: <a href=\"~A\">~A</a>
</p>
<p>
Gopher ftw!!1
</p>
</body>
</html>
"
	  url url url))

(defun write-error (stream error)
  (format stream "~C~A~C~C~%~C~A~C~C"
	  #\3 error #\Return #\Linefeed
	  #\i "Root directory listing follows:" #\Return #\Linefeed)
  (write-directory-resource stream *gopher-root*))

(defun serve-client (client)
  (handler-case
      (let ((client-stream (socket-make-stream
			    client
			    :element-type :default
			    :input t
			    :output t)))
	(handler-case
	    (write-resource
	     client-stream
	     (parse-selector
	      (first
	       (seqsep #\Tab
		       (remove-if
			(lambda (item)
			  (case item
			    ((#\Return
			      #\Linefeed) t)
			    (otherwise nil)))
			(read-line client-stream))))))
	  (bad-pathname (condition)
	    (let* ((path (path condition))
		   (url-start
		    (mismatch path "URL:" :test #'char=)))
	      (if (= (or url-start 0) 4)
		  (write-html-redirect
		   client-stream
		   (subseq path url-start))
		  (write-error client-stream
			       (concatenate 'string
					    "Bad selector: "
					    path))))))
	(socket-close client))
	       (socket-error () nil)
	       (stream-error () nil)))

(defun serve-clients (socket)
  (loop
     (serve-client (socket-accept socket))))

(defun serve (root host-name &key ((:port port) 70) ((:address address) nil) ((:debug debug) nil))
  (let ((*host* host-name)
	(*port* port)
	socket)
    (handler-case
	(progn
	  (setf *gopher-root* (probe-file root))
	  (unless *gopher-root*
	    (error "Root existeth not."))
	  (setf socket (make-instance 'inet-socket :type :stream :protocol :tcp))
	  (setf (sockopt-reuse-address socket) t)
					;     (setf (sockopt-reuse-port socket) t)
	  (socket-bind socket
		       (or
			address
			(host-ent-address
			 (get-host-by-name *host*)))
		       port)
	  (socket-listen socket 20)
	  (sb-posix:setgid (sb-posix:getgid))
	  (sb-posix:setuid (sb-posix:getuid))
	  (serve-clients socket))
      (t (condition)
	(if debug
	    (invoke-debugger condition)
	    (sb-posix:syslog
	     sb-posix:log-err
	     (format
	      nil
	      "Dying due to unknown error. Condition type: ~A"
	      (type-of condition))))))
    (socket-close socket)))