(in-package :cl-user)

(defvar *build-dir* (pathname-directory (pathname (concatenate 'string (getenv "BUILD_DIR") "/"))))
(defvar *cache-dir* (pathname-directory (pathname (concatenate 'string (getenv "CACHE_DIR") "/"))))
(defvar *buildpack-dir* (pathname-directory (pathname (concatenate 'string (getenv "BUILDPACK_DIR") "/"))))

;;; Tell ASDF to store binaries in the cache dir
(ccl:setenv "XDG_CACHE_HOME" (concatenate 'string (getenv "CACHE_DIR") "/.asdf/"))

(require :asdf)

(let ((ql-setup (make-pathname :directory (append *cache-dir* '("quicklisp")) :defaults "setup.lisp")))
  (if (probe-file ql-setup)
      (load ql-setup)
      (progn
	(load (make-pathname :directory (append *buildpack-dir* '("lib")) :defaults "quicklisp.lisp"))
	(funcall (symbol-function (find-symbol "INSTALL" (find-package "QUICKLISP-QUICKSTART")))
		 :path (make-pathname :directory (pathname-directory ql-setup))))))

(asdf:clear-system "acl-compat")

(load (make-pathname :directory (append *cache-dir* '("repos" "portableaserve" "acl-compat"))
		     :defaults "acl-compat.asd"))
(load (make-pathname :directory (append *cache-dir* '("repos" "portableaserve" "aserve"))
		     :defaults "aserve.asd"))

;;; App can redefine this to do runtime initializations
(defun initialize-application ()
  )

;;; Default toplevel, app can redefine 
(defun heroku-toplevel ()
  (initialize-application)
  (let ((port (parse-integer (getenv "PORT"))))
    (format t "Listening on port ~A~%" port)
    (funcall (symbol-function (find-symbol "START" (find-package "NET.ASERVE")))
	     :port port)
    (loop (sleep 60))			;sleep forever
    ))

;;; This loads the application
(load (make-pathname :directory *build-dir* :defaults "heroku-setup.lisp"))

(let ((app-file (format nil "~A/lispapp" (getenv "BUILD_DIR")))) ;must match path specified in bin/release
  (format t "Saving to ~A~%" app-file)
  (save-application app-file
		    :prepend-kernel t
		    :toplevel-function #'heroku-toplevel
		    ))
