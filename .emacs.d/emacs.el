;;-----------------------------
;; Utils
;;-----------------------------
(require 'cl)
(require 'cl-lib)

(setq lisp-indent-function #'common-lisp-indent-function)

(defmacro -> (x &rest forms)
  (if (null forms) x
    (let ((head (car forms)))
      (cond ((listp head)
             `(-> (,(car head) ,x ,@(cdr head)) ,@(cdr forms)))
            ((symbolp head)
             `(-> (,head ,x) ,@(cdr forms)))
            (t
             `(-> ,head ,@(cdr forms)))))))

(defmacro ->> (x &rest forms)
  (if (null forms) x
    (let ((head (car forms)))
      (cond ((listp head)
             `(->> (,@head ,x) ,@(cdr forms)))
            ((symbolp head)
             `(->> (,head ,x) ,@(cdr forms)))
            (t
             `(->> ,head ,@(cdr forms)))))))

(defmacro doto-> (x &rest forms)
  (let ((gx (gensym)))
    `(let ((,gx ,x))
       ,@(mapcar (lambda (f) `(-> ,gx ,f)) forms)
       ,gx)))

(defmacro doto->> (x &rest forms)
  (let ((gx (gensym)))
    `(let ((,gx ,x))
       ,@(mapcar (lambda (f) `(->> ,gx ,f)) forms)
       ,gx)))

(defmacro todo-> (fn &rest forms)
  `(progn
     ,@(mapcar (lambda (f)
                 (if (listp f)
                     `(apply #',fn (list ,@f))
                     `(apply #',fn (list ,f))))
               forms)))

(defun assoc! (source key val)
  (let ((point (assoc key source)))
    (if (consp point)
        (setcdr point val)
        (nconc source (list (cons key val))))))


;;-----------------------------
;; Require Local EmacsLisp
;;-----------------------------

(defun add-to-load-path (&rest paths)
  (let (path)
    (dolist (path paths paths)
      (let ((default-directory
              (expand-file-name
               (concat user-emacs-directory path))))
        (add-to-list 'load-path default-directory)
        (if (fboundp 'normal-top-level-add-subdirs-to-load-path)
            (normal-top-level-add-subdirs-to-load-path))))))


;;-----------------------------
;; Tmp Directory
;;-----------------------------

(defun mkdir (path)
  (if (file-directory-p path) nil (make-directory path)))

(defun tmp-directory (&optional file-name)
  (let ((dir (file-truename "~/.tmp")))
    (if file-name (format "%s/%s" dir file-name) dir)))


;;-----------------------------
;; Load *.config.el
;;-----------------------------

(defun config-el-p (conf)
  (string-match "\\.config\\.el$" conf))

(defun load-config-file (conf)
  (if (config-el-p conf)
      (load conf)))

(defun load-config-directory (path)
  (let* ((path (expand-file-name path))
         (files (directory-files path)))
    (dolist (x files)
      (load-config-file x))))

(defun load-configs (path)
  (load-config-directory
      (locate-user-emacs-file path)))


