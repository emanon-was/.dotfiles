;;-----------------------------
;; Utils
;;-----------------------------
(require 'cl)
(require 'cl-lib)

(setq lisp-indent-function #'common-lisp-indent-function)

(defun clj-lambda-symbols (form)
  (cl-labels ((rec (form)
                (if (consp form)
                    (nconc (rec (car form)) (rec (cdr form)))
                    (if (symbolp form)
                        (let ((name (symbol-name form)))
                          (if (string-match "^%[1-9&]?$" name)
                              (list name)))))))
    (mapcar #'intern (sort (delete-duplicates (rec form)) #'string<))))

(defun clj-lambda-arguments (form)
  (let ((args (clj-lambda-symbols form)))
    (cond ((equal args '(%))    '(%))
          ((equal args '(%&))   '(&rest %&))
          ((equal args '(% %&)) '(% &rest %&))
          ((memq '% args) (error "%% should not be in %s, use %%1 instead" args))
          (t (let* ((max-arg (car (last args)))
                    (max-int-arg (string-to-int (substring (symbol-name max-arg) 1)))
                    (num-args (mapcar (lambda (x) (intern (format "%%%d" x)))
                                      (number-sequence 1 max-int-arg))))
               (if (memq '%& args)
                   `(,@num-args &rest %&)
                   num-args))))))

(defmacro clj-lambda (form)
  `(lambda ,(clj-lambda-arguments form) ,form))

(defmacro clj-funcall (form &rest args)
  (if (listp form)
      `(funcall ,`(clj-lambda ,form) ,@args)
      `(,form ,@args)))

(defmacro -> (x &optional form &rest more)
  (cond ((null form) x)
        ((null more)
         (if (listp form)
             `(,(car form) ,x ,@(cdr form))
             `(,form ,x)))
        (:else `(-> (-> ,x ,form) ,@more))))

(defmacro ->> (x &optional form &rest more)
  (cond   ((null form) x)
          ((null more)
           (if (listp form)
               `(,@form ,x)
               `(,form ,x)))
          (:else `(->> (->> ,x ,form) ,@more))))

(defmacro doto (x &rest forms)
  (let ((gx (gensym)))
    (labels ((doto-form (form) `(clj-funcall ,form ,gx)))
      `(let ((,gx ,x))
         ,@(mapcar #'doto-form forms)
         ,gx))))

(defmacro todo (form &rest args)
  (labels ((todo-form (arg)
             (if (listp arg)
                 (if (special-form-p (car arg))
                     `(clj-funcall ,form ,arg)
                     `(clj-funcall ,form ,@arg))
                 `(clj-funcall ,form ,arg))))
    `(progn ,@(mapcar #'todo-form args))))

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


