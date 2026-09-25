;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
;; (setq user-full-name "John Doe"
;;       user-mail-address "john@doe.com")
(setq user-full-name "Daigo Kawasaki"
      user-mail-address "emanon.was@gmail.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-symbol-font' -- for symbols
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
;;(setq doom-font (font-spec :family "Fira Code" :size 12 :weight 'semi-light)
;;      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-one)

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")


;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `with-eval-after-load' block, otherwise Doom's defaults may override your
;; settings. E.g.
;;
;;   (with-eval-after-load 'PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look them up).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.

(setq select-enable-clipboard t)

;; Terminal Emacs uses the host clipboard tools; graphical frames keep their
;; native selection backend.  WSL takes precedence over WSLg's displays.
(defvar dotfiles-clipboard-copy-command nil)
(defvar dotfiles-clipboard-paste-command nil)
(defvar dotfiles-clipboard-write-coding 'utf-8-unix)

(cond
 ((and (getenv "WSL_DISTRO_NAME")
       (executable-find "clip.exe") (executable-find "powershell.exe"))
  (setq dotfiles-clipboard-copy-command '("clip.exe")
        dotfiles-clipboard-write-coding 'utf-16le-dos
        dotfiles-clipboard-paste-command
        '("powershell.exe" "-NoLogo" "-NoProfile" "-NonInteractive" "-Command"
          "[Console]::OutputEncoding = [System.Text.Encoding]::UTF8; [Console]::Write((Get-Clipboard -Raw))")))
 ((and (eq system-type 'darwin)
       (executable-find "pbcopy") (executable-find "pbpaste"))
  (setq dotfiles-clipboard-copy-command '("pbcopy")
        dotfiles-clipboard-paste-command '("pbpaste")))
 ((and (getenv "WAYLAND_DISPLAY")
       (executable-find "wl-copy") (executable-find "wl-paste"))
  (setq dotfiles-clipboard-copy-command '("wl-copy" "--type" "text/plain;charset=utf-8")
        dotfiles-clipboard-paste-command '("wl-paste" "--no-newline" "--type" "text")))
 ((and (getenv "DISPLAY") (executable-find "xclip"))
  (setq dotfiles-clipboard-copy-command '("xclip" "-selection" "clipboard" "-in")
        dotfiles-clipboard-paste-command '("xclip" "-selection" "clipboard" "-out"))))

(cl-defmethod gui-backend-set-selection :around
  (selection value &context (window-system nil))
  (if (and dotfiles-clipboard-copy-command
           (memq selection '(CLIPBOARD PRIMARY)) (stringp value))
      (let ((coding-system-for-write dotfiles-clipboard-write-coding))
        (unless (eq 0 (apply #'call-process-region value nil
                             (car dotfiles-clipboard-copy-command) nil nil nil
                             (cdr dotfiles-clipboard-copy-command)))
          (error "System clipboard copy failed")))
    (cl-call-next-method)))

(cl-defmethod gui-backend-get-selection :around
  (selection target-type &context (window-system nil))
  (if (and dotfiles-clipboard-paste-command
           (memq selection '(CLIPBOARD PRIMARY)))
      (with-temp-buffer
        (let ((coding-system-for-read 'utf-8-dos))
          (when (eq 0 (apply #'call-process
                             (car dotfiles-clipboard-paste-command) nil '(t nil) nil
                             (cdr dotfiles-clipboard-paste-command)))
            (buffer-string))))
    (cl-call-next-method)))

;; n: normal
;; v: visual
;; i: insert
;; o: operator
;; r: replace
;; m: motion
;; e: emacs
;; g: global

(map! :iorme "C-h" #'backward-delete-char-untabify)
(map! :nv "TAB" #'evil-indent)
(map! :nv "#" #'evilnc-comment-or-uncomment-lines)
(map! :nv "%" #'query-replace-regexp)

;;
;; For Evil users:
;;   doom-leader-key (default: "SPC")
;;   doom-localleader-key (default: "SPC m")
;; For Emacs and Insert state (evil users), and non-evil users:
;;   doom-leader-alt-key (default: "M-SPC" for evil users, "C-c" otherwise)
;;   doom-localleader-alt-key (default: "M-SPC m" for evil users, "C-c l" otherwise)
;;

;; "SPC c q" = #'query-replace
(map! :leader (:desc "Query & replace" :prefix "c" "q" #'query-replace))
;; "SPC c Q" = #'query-replace-regexp
(map! :leader (:desc "Query & replace/regex" :prefix "c" "Q" #'query-replace-regexp))


;; Doom dashboard は menu item 間に `relative-height 0.01' の spacer を入れる。
;; terminal Emacs ではそれが潰れず空行として見えることがあるため、terminal
;; のときだけ該当 spacer を取り除く。
(defun dotfiles-doom-dashboard-drop-terminal-menu-spacers (args)
  (if (display-graphic-p)
      args
    (cl-remove-if
     (lambda (arg)
       (and (stringp arg)
            (string= arg "\n")
            (equal (get-text-property 0 'display arg)
                   '(space . (:relative-height 0.01)))))
     args)))

(defun dotfiles-doom-dashboard-setup ()
  (advice-add #'+dashboard-insert
              :filter-args
              #'dotfiles-doom-dashboard-drop-terminal-menu-spacers))

(add-hook 'doom-init-ui-hook #'dotfiles-doom-dashboard-setup)
