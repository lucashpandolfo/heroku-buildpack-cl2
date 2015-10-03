(in-package :cl-user)

(require :asdf)

(defvar *build-dir* (pathname (concatenate 'string (uiop:getenv "BUILD_DIR") "/")))
(defvar *cache-dir* (pathname (concatenate 'string (uiop:getenv "CACHE_DIR") "/")))
(defvar *asdf-dir*  (pathname (concatenate 'string (uiop:getenv "CACHE_DIR") "/asdf/")))
(defvar *buildpack-dir* (pathname (concatenate 'string (uiop:getenv "BUILDPACK_DIR") "/")))

(defun heroku-setup-cache ()
  (setf (uiop:getenv "XDG_CACHE_HOME") *asdf-dir*))

(defmacro fncall (funname &rest args)
  `(funcall (read-from-string ,funname) ,@args))

(defun require-quicklisp (&key version)
  "VERSION if specified must be in format YYYY-MM-DD"
  (let ((ql-setup (merge-pathnames "quicklisp/setup.lisp" *build-dir*)))
    (if (probe-file ql-setup)
        (load ql-setup)
        (progn
          (load (merge-pathnames "bin/quicklisp.lisp" *buildpack-dir*))
          (fncall "quicklisp-quickstart:install"
                   :path (make-pathname :directory (pathname-directory ql-setup)))))
    (when version
      (fncall "ql-dist:install-dist"
              (format nil "http://beta.quicklisp.org/dist/quicklisp/~A/distinfo.txt"
                      version)
              :replace t :prompt nil))))

(defun call-with-ql-test-context (thunk)
  (block nil
    (handler-bind (((or error serious-condition)
                     (lambda (c)
                       (format *error-output* "~%~A~%" c)
                       (print-backtrace)
                       (format *error-output* "~%~A~%" c)
                       (return nil))))
      (funcall thunk))))

(defmacro with-ql-test-context (() &body body)
  `(call-with-ql-test-context #'(lambda () ,@body)))

;;; Load the application compile script
(with-ql-test-context ()
  (heroku-setup-cache)
  (load (merge-pathnames "heroku-compile.lisp" *build-dir*)))
