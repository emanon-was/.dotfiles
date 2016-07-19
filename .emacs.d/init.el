
;;-----------------------------
;; Setup Emacs
;;-----------------------------

(load (locate-user-emacs-file "emacs.el"))
(add-to-load-path "elisp" "config" "package")
(mkdir (tmp-directory))


;;-----------------------------
;; Load package
;;-----------------------------
(require 'package)
(package-initialize)
(setq url-configuration-directory (tmp-directory "url"))
(setq package-user-dir (locate-user-emacs-file "package"))
(setq package-archives
      '(("gnu"          . "https://elpa.gnu.org/packages/")
        ("melpa"        . "https://melpa.org/packages/")
        ("melpa-stable" . "https://stable.melpa.org/packages/")
        ("marmalade"    . "https://marmalade-repo.org/packages/")))


;;---------------------------------
;; Setting UTF-8
;;---------------------------------
;;(set-language-environment "Japanese")
(doto 'utf-8
      set-terminal-coding-system
      prefer-coding-system
      set-keyboard-coding-system
      set-default-coding-systems)


;;---------------------------------------
;; Setting Indent
;;---------------------------------------
(setq-default tab-width 2)
(setq-default indent-tabs-mode nil)
(setq c-basic-offset 2)
(setq js-indent-level 2)


;;---------------------------------------
;; Setting toolbar
;;---------------------------------------
(if (fboundp 'tool-bar-mode)
    (tool-bar-mode t))

(if window-system
    (menu-bar-mode 1)
    (menu-bar-mode -1))


;;---------------------------------------
;; Setting auto save
;;---------------------------------------
(setq backup-inhibited t)
(setq auto-save-list-file-name nil)
(setq auto-save-list-file-prefix (tmp-directory "auto-save-list"))


;;-------------------
;; Extention dired
;;-------------------
(require 'dired-x)
(require 'wdired)
(define-key dired-mode-map "r" 'wdired-change-to-wdired-mode)


;;--------------------
;; Setting eshell
;;--------------------
(setq eshell-cmpl-ignore-case t)
(setq eshell-history-file-name (tmp-directory "eshell_history"))


;;-------------------------
;; Setting bookmark
;;-------------------------
(setq bookmark-default-file (tmp-directory "bookmark"))
(setq bookmark-save-flag 1)
(setq bookmark-sort-flag nil)
(todo (global-set-key (kbd %1) %2)
      ("\C-c r l" 'bookmark-bmenu-list)
      ("\C-c r b" 'bookmark-jump)
      ("\C-c r m" 'bookmark-set))


;;-------------------------
;; Setting filecache
;;-------------------------
(require 'filecache)

(defun file-cache-reset ()
  (interactive)
  (file-cache-clear-cache))

(file-cache-reset)
(todo (global-set-key (kbd %1) %2)
      ("\C-c c d" 'file-cache-add-directory)
      ("\C-c c t" 'file-cache-add-directory-recursively))


;;---------------------
;; Setting global-set-keys
;;---------------------
(todo (global-set-key (kbd %1) %2)
      ("C-x ?" 'help-command)
      ("C-h" 'delete-backward-char)
      ("C-u" 'repeat)
      ("C-x C-d" 'dired)
      ("C-x g" 'rgrep)
      ("C-x ," 'backward-word)
      ("C-x ." 'forward-word))

(todo (define-key global-map %1 %2)
      ([f1] 'start-kbd-macro)
      ([f2] 'end-kbd-macro)
      ([f3] 'call-last-kbd-macro))


;;---------------------
;; Setting kill-line
;;---------------------
(setq kill-whole-line t)


;;---------------------------
;; Setting paren-mode
;;---------------------------
(show-paren-mode 1)
(setq skeleton-pair 1)
(todo (global-set-key (kbd %) 'skeleton-pair-insert-maybe)
      "(" "{" "[" "<")


;;-------------------------
;; Setting recentf
;;-------------------------
(setq recentf-save-file (tmp-directory "recentf"))
(setq recentf-max-saved-items 500)
(setq recentf-auto-save-timer (run-with-idle-timer 30 t 'recentf-save-list))
(require 'recentf-ext)


;;--------------------
;; Setting tramp
;;--------------------
(setq tramp-persistency-file-name (tmp-directory "tramp"))


;;-------------------
;; Setting undo,redo
;;-------------------
(require 'undo-tree)
(setq undo-no-redo t)
(global-undo-tree-mode)
(global-set-key (kbd "M-,") 'undo)
(global-set-key (kbd "M-.") 'redo)


;;---------------------------------------------------------
;; Setting uniquify
;;---------------------------------------------------------
(require 'uniquify)

;; filename<dir>
(setq uniquify-buffer-name-style 'post-forward-angle-brackets)
(setq uniquify-ignore-buffers-re "*[^*]+*")


;;-------------------------
;; Setting company-mode
;;-------------------------
(require 'company)
(global-company-mode)
(setq company-idle-delay 0)
(setq company-minimum-prefix-length 2)
(setq company-selection-wrap-around t)
(setq company-dabbrev-downcase nil)
(setq company-backends
      '((company-capf
         company-files
         company-dabbrev-code
         company-keywords
         company-dabbrev)))

(todo (define-key company-active-map (kbd %1) %2)
      ("C-h" nil)
      ("M-n" nil)
      ("M-p" nil)
      ("C-n" 'company-select-next)
      ("C-p" 'company-select-previous)
      ("C-s" 'company-filter-candidates)
      ("C-i" 'company-complete-selection))

(todo (define-key company-search-map (kbd %1) %2)
      ("C-n" 'company-select-next)
      ("C-p" 'company-select-previous))

(todo set-face-attribute
      ('company-tooltip nil :foreground "black" :background "lightgrey")
      ('company-tooltip-common nil :foreground "black" :background "lightgrey")
      ('company-tooltip-common-selection nil :foreground "white" :background "steelblue")
      ('company-tooltip-selection nil :foreground "black" :background "steelblue")
      ('company-preview-common nil :background nil :foreground "lightgrey" :underline t)
      ('company-scrollbar-fg nil :background "orange")
      ('company-scrollbar-bg nil :background "gray40"))


;;-------------------------
;; Setting key-combo
;;-------------------------
(require 'key-combo)
(global-key-combo-mode t)

(todo (key-combo-define-global (kbd %1) %2)
      ("C-a" '(back-to-indentation beginning-of-line beginning-of-buffer key-combo-return))
      ("C-e" '(end-of-line end-of-buffer key-combo-return)))


;;---------------------------
;; Setting linum
;;---------------------------
(require 'linum+)
(global-linum-mode t)


;;-------------------------
;; Setting mmm-mode
;;-------------------------
(require 'mmm-auto)

(setq mmm-global-mode 'auto)
(setq mmm-submode-decoration-level 2)
(setq mmm-parse-when-idle t)

(mmm-add-classes
 '((js-tag  :submode javascript-mode :front "<script[^>]*>[ \n]?" :back  "[ \n]?</script>")
   (css-tag :submode css-mode :front "<style[^>]*>[ \n]?" :back  "[ \n]?</style>")
   (erb-tag :submode ruby-mode :front "<%[ \n]?" :back "[ \n]?%>")
   (gsp-tag :submode text-mode :front "<%[ \n]?" :back "[ \n]?%>")))

(todo mmm-add-mode-ext-class
      ('html-mode nil 'js-tag)
      ('html-mode nil 'css-tag)
      ('html-mode "\\.erb\\'" 'erb-tag)
      ('html-mode "\\.gsp\\'" 'gsp-tag))


;;---------------------------------------
;; Setting tmpbuf
;;---------------------------------------
(require 'tempbuf)
(todo (add-hook % 'turn-on-tempbuf-mode)
      'find-file-hooks
      'dired-mode-hook)


;;--------------------
;; Setting helm
;;--------------------
(require 'helm-config)
(helm-mode t)
(setq helm-M-x-requires-pattern 0)

(todo (global-set-key (kbd %1) %2)
      ("M-x" 'helm-M-x)
      ("M-y" 'helm-show-kill-ring)
      ("C-c o" 'helm-occur)
      ("C-x b" 'helm-for-files)
      ("C-x C-b" 'helm-for-files))

(todo (define-key helm-map (kbd %1) %2)
      ("C-h" 'delete-backward-char)
      ("TAB" 'helm-execute-persistent-action))

(remove-hook
 'helm-after-update-hook
 'helm-ff-update-when-only-one-matched)

(define-obsolete-variable-alias
  'last-command-char
  'last-command-event)

(todo (assoc! %1 'candidate-number-limit %2)
      (helm-source-recentf 15)
      (helm-source-buffers-list 15)
      (helm-source-file-cache 10)
      (helm-source-locate 5)
      (helm-source-files-in-current-dir 5))


;;-------------------------
;; Load *.config.el
;;-------------------------

(load-configs "config")

