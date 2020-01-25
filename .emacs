;;; .emacs --- Summary:
;;; Commentary:
;;; Code:


(prefer-coding-system 'utf-8)
(set-language-environment "UTF-8")


;;; package things


(package-initialize)

;; enable package-loading from MELPA
(require 'package)
(push '("melpa" . "https://melpa.org/packages/") package-archives)

;; these things are used by multiple major modes and/or get configured before any
;; buffers are opened, so they're not good candidates for autoload

;; code completion
(require 'company)
(require 'company-quickhelp)
;; mode line cleaner-upper
(require 'delight)
;; linting
(require 'flymake)
;; mode line customization
(require 'powerline)

;; these guys, however...

(autoload 'coverlay-mode "coverlay"
  "Use the coverlay package to provide 'coverlay-mode on-demand."
  t)
(autoload 'flymake-eslint-enable "flymake-eslint"
  "Use the flymake-eslint package to provide 'flymake-eslint-enable on-demand."
  t)
(autoload 'flymake-stylelint-enable "flymake-stylelint"
  "Use the flymake-stylelint package to provide 'flymake-stylelint-enable on-demand."
  t)
(autoload 'json-mode "json-mode"
  "Use the json-mode package to provide 'json-mode on-demand."
  t)
(autoload 'markdown-mode "markdown-mode"
  "Use the markdown-mode package to provide 'markdown-mode on-demand."
  t)
(autoload 'rjsx-mode "rjsx-mode"
  "Use the rjsx-mode package to provide 'rjsx-mode on-demand."
  t)
(autoload 'scss-mode "scss-mode"
  "Use the scss-mode package to provide 'scss-mode on-demand."
  t)
(autoload 'tide-setup "tide"
  "Use the tide package to provide 'tide-setup on-demand."
  t)


;;; utility functions and advices


(defun backward-delete-word (arg)
  "Delete characters backward until encountering the beginning of a word.
With argument ARG, do this that many times."
  (interactive "p")
  (delete-word (- arg)))

(defun delete-word (arg)
  "Delete characters forward until encountering the end of a word.
With argument ARG, do this that many times."
  (interactive "p")
  (delete-region (point) (progn (forward-word arg) (point))))

(defun eslint-fix-buffer ()
  "Run `eslint --fix' on current buffer."
  (interactive)
  (if (executable-find "eslint_d")
      (progn
        (call-process "eslint_d" nil "*ESLint Errors*" nil "--fix" buffer-file-name)
        (revert-buffer t t t))
    (message "eslint_d not found")))

;; prefer contents of help-at-point (e.g., Flymake) over whatever eldoc outputs
(advice-add 'eldoc-message :around
            (lambda (oldfn doc-msg)
              (let ((echo-help-string (help-at-pt-string)))
                (if echo-help-string
                    (display-local-help)
                  (funcall oldfn doc-msg)))))

;; tell powerline to use the modifications made by delight
(advice-add 'powerline-major-mode :around
            (lambda (original-fn &rest args)
              (let ((inhibit-mode-name-delight nil))
                (funcall original-fn args))))
;; shorten some major-mode modeline strings
(delight '((emacs-lisp-mode "ELisp")))
;; remove some minor-mode modeline strings
(delight '((subword-mode nil "subword")
           (company-mode nil "company")
           (tide-mode nil "tide")
           (coverlay-minor-mode nil "coverlay")
           (eldoc-mode nil "eldoc")
           (auto-dim-other-buffers-mode nil "auto-dim-other-buffers")))
;; shorten dynamically-generated Flymake minor-mode string
(advice-add 'flymake--mode-line-format :filter-return
            (lambda (&rest return-value)
              (setf (seq-elt (car return-value) 0) "✓")
              return-value))


;;; mode hooks and config


(defun my-css-mode-hook ()
  "Do some things when opening [S]CSS files."
  (company-mode t)
  (eldoc-mode t)
  (flymake-stylelint-enable)
  (subword-mode t))

(defun my-flymake-mode-hook ()
  "Do some things when enabling Flymake."
  (help-at-pt-set-timer)
  (setq-local help-at-pt-display-when-idle t))

(defun my-javascript-mode-hook ()
  "Do some things when opening JavaScript files."
  ;; enable code analysis
  (tide-setup)
  ;; enable camelCase-aware code navigation
  (subword-mode t)
  ;; enable linting
  (flymake-eslint-enable)
  (setq flymake-eslint-project-root (locate-dominating-file buffer-file-name ".eslintrc.js"))
  ;; enable code-completion
  (company-mode t)
  ;; enable documentation
  (eldoc-mode t)
  ;; run `eslint --fix' upon save
  (add-hook 'after-save-hook 'eslint-fix-buffer t t)
  ;; turn on coverage mode if not a test file
  (unless (string-match-p "test.js[x]?\\'" buffer-file-name)
    (coverlay-minor-mode t)
    (unless (bound-and-true-p coverlay--loaded-filepath)
      ;; load the closest coverage file if one hasn't been loaded yet
      (coverlay-watch-file (concat (locate-dominating-file buffer-file-name "coverage")
                                   "coverage/lcov.info")))))

(defun my-json-mode-hook ()
  "Do some things when opening JSON files."
  (make-local-variable 'js-indent-level)
  (set 'js-indent-level 2)
  ;; enable camelCase-aware navigation
  (subword-mode t))

(defun common-lisp-mode-hook ()
  "Do some things when entering a Lisp mode."
  ;; enable code-completion mode
  (company-mode t)
  (company-quickhelp-mode t)
  ;; enable documentation in echo area
  (eldoc-mode t)
  ;; linter (most of the time)
  (when (not (string= (buffer-name) "*scratch*"))
    (flymake-mode t)))

(defun my-terminal-mode-hook ()
  "Do some things when opening a terminal."
  ;; for terminals only, we want the default face to be reversed
  (face-remap-add-relative 'default '((:background "black") (:foreground "white")))
  (subword-mode nil))

(add-hook 'scss-mode-hook 'my-css-mode-hook)
(add-hook 'emacs-lisp-mode-hook 'common-lisp-mode-hook)
(add-hook 'rjsx-mode-hook 'my-javascript-mode-hook)
(add-hook 'json-mode-hook 'my-json-mode-hook)
(add-hook 'lisp-mode-hook 'common-lisp-mode-hook)
(add-hook 'term-mode-hook 'my-terminal-mode-hook)
(add-hook 'flymake-mode-hook 'my-flymake-mode-hook)

;; associate some major modes with some file extensions
(push '("\\.js[x]?\\'" . rjsx-mode) auto-mode-alist)
(push '("\\.json\\'" . json-mode) auto-mode-alist)
(push '("\\.[s]?css\\'" . scss-mode) auto-mode-alist)
(push '("\\.less\\'" . scss-mode) auto-mode-alist)
(push '("\\.md\\'" . markdown-mode) auto-mode-alist)


;;; variables and faces


;; replace the stock Flymake warning/error indicators with a bigger one for hidpi
;; maxmum width is 16px according to emacs docs
(define-fringe-bitmap 'flymake-big-indicator
  (vector #b0000000000000000
          #b0000000000000000
          #b0000000000000000
          #b0111000111000000
          #b0011100011100000
          #b0001110001110000
          #b0000111000111000
          #b0000011100011100
          #b0000011100011100
          #b0000111000111000
          #b0001110001110000
          #b0011100011100000
          #b0111000111000000
          #b0000000000000000
          #b0000000000000000
          #b0000000000000000)
  16 16 'center)

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(auto-dim-other-buffers-mode t)
 '(backup-by-copying t)
 '(blink-cursor-mode nil)
 '(company-minimum-prefix-length 1)
 '(company-quickhelp-color-background nil)
 '(company-quickhelp-color-foreground nil)
 '(company-quickhelp-delay 1.0)
 '(company-tooltip-align-annotations t)
 '(coverlay:mark-tested-lines nil)
 '(coverlay:untested-line-background-color "#ffe8e8")
 '(cua-mode t nil (cua-base))
 '(flymake-error-bitmap (quote (flymake-big-indicator compilation-error)))
 '(flymake-eslint-executable-name "eslint_d")
 '(flymake-jslint-args (quote ("--no-color" "--no-ignore" "--stdin")))
 '(flymake-jslint-command "eslint")
 '(flymake-no-changes-timeout 0.5)
 '(flymake-stylelint-executable-args "-q")
 '(flymake-stylelint-executable-name "stylelint")
 '(flymake-warning-bitmap (quote (flymake-big-indicator compilation-warning)))
 '(font-use-system-font t)
 '(frame-title-format (quote ("%f")) t)
 '(fringe-mode 20 nil (fringe))
 '(help-at-pt-display-when-idle (quote (flymake-diagnostic)) nil (help-at-pt))
 '(help-at-pt-timer-delay 0.25)
 '(indent-tabs-mode nil)
 '(inhibit-startup-screen t)
 '(js-chain-indent nil)
 '(js-enabled-frameworks nil)
 '(js-switch-indent-offset 4)
 '(js2-highlight-external-variables nil)
 '(js2-include-browser-externs nil)
 '(js2-include-jslint-declaration-externs nil)
 '(js2-include-jslint-globals nil)
 '(js2-indent-switch-body t)
 '(js2-mode-show-parse-errors nil)
 '(js2-mode-show-strict-warnings nil)
 '(js2-strict-cond-assign-warning nil)
 '(js2-strict-inconsistent-return-warning nil)
 '(js2-strict-missing-semi-warning nil)
 '(js2-strict-var-hides-function-arg-warning nil)
 '(js2-strict-var-redeclaration-warning nil)
 '(menu-bar-mode nil)
 '(mode-line-format
   (quote
    ("%e"
     (:eval
      (let*
          ((active
            (powerline-selected-window-active))
           (mode-line-buffer-id
            (if active
                (quote mode-line-buffer-id)
              (quote mode-line-buffer-id-inactive)))
           (mode-line
            (if active
                (quote mode-line)
              (quote mode-line-inactive)))
           (face0
            (if active
                (quote powerline-active0)
              (quote powerline-inactive0)))
           (face1
            (if active
                (quote powerline-active1)
              (quote powerline-inactive1)))
           (face2
            (if active
                (quote powerline-active2)
              (quote powerline-inactive2)))
           (separator-left
            (intern
             (format "powerline-%s-%s"
                     (powerline-current-separator)
                     (car powerline-default-separator-dir))))
           (separator-right
            (intern
             (format "powerline-%s-%s"
                     (powerline-current-separator)
                     (cdr powerline-default-separator-dir))))
           (lhs
            (list
             (powerline-raw "%*" face0
                            (quote l))
             (powerline-buffer-id
              (\`
               (mode-line-buffer-id
                (\, face0)))
              (quote l))
             (powerline-raw " " face0)
             (funcall separator-left face0 face1)
             (powerline-raw " " face1)
             (powerline-major-mode face1)
             (powerline-process face1)
             (powerline-minor-modes face1
                                    (quote l))
             (powerline-narrow face1
                               (quote l))
             (powerline-raw " " face1)
             (funcall separator-left face1 face2)
             (powerline-vc face2
                           (quote r))))
           (rhs
            (list
             (powerline-raw global-mode-string face2
                            (quote r))
             (funcall separator-right face2 face1)
             (unless window-system
               (powerline-raw
                (char-to-string 57505)
                face1
                (quote l)))
             (powerline-raw "%4l" face1
                            (quote l))
             (powerline-raw ":" face1
                            (quote l))
             (powerline-raw "%3c" face1
                            (quote r))
             (funcall separator-right face1 face0)
             (powerline-raw " " face0)
             (powerline-fill face0 0))))
        (concat
         (powerline-render lhs)
         (powerline-fill face2
                         (powerline-width rhs))
         (powerline-render rhs)))))))
 '(package-selected-packages
   (quote
    (projectile treemacs-projectile treemacs 2048-game dockerfile-mode tide request flymake-stylelint company auto-dim-other-buffers scss-mode rjsx-mode powerline markdown-mode json-mode flymake-eslint delight coverlay company-quickhelp)))
 '(powerline-display-buffer-size nil)
 '(powerline-display-hud nil)
 '(powerline-display-mule-info nil)
 '(powerline-gui-use-vcs-glyph t)
 '(scroll-bar-mode nil)
 '(sgml-basic-offset 4)
 '(tool-bar-mode nil))

(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(default ((t (:inherit nil :stipple nil :background "white" :foreground "black" :inverse-video nil :box nil :strike-through nil :overline nil :underline nil :slant normal :weight light :height 132 :width normal :foundry "ADBO" :family "Source Code Pro"))))
 '(auto-dim-other-buffers-face ((t (:background "#f4f4f4" :foreground "#808080"))))
 '(company-preview ((t (:inherit company-tooltip-selection))))
 '(company-scrollbar-bg ((t (:background "gray95"))))
 '(company-scrollbar-fg ((t (:background "tomato"))))
 '(company-tooltip-annotation ((t (:foreground "firebrick4"))))
 '(company-tooltip-common ((t (:foreground "black"))))
 '(company-tooltip-selection ((t (:background "steel blue" :foreground "white"))))
 '(flymake-warning ((t (:underline (:color "dark orange" :style wave)))))
 '(font-lock-comment-face ((t (:inherit default :foreground "Firebrick"))))
 '(font-lock-doc-face ((t (:inherit font-lock-comment-face))))
 '(font-lock-function-name-face ((t (:foreground "steel blue" :weight bold))))
 '(js2-error ((t nil)))
 '(js2-external-variable ((t nil)))
 '(js2-function-call ((t (:inherit font-lock-function-name-face :weight normal))))
 '(js2-jsdoc-html-tag-name ((t (:inherit js2-jsdoc-type))))
 '(js2-jsdoc-tag ((t (:inherit font-lock-comment-face :weight bold))))
 '(js2-jsdoc-value ((t (:inherit js2-function-param))))
 '(js2-warning ((t nil)))
 '(mode-line ((t (:background "grey75" :foreground "black"))))
 '(powerline-active0 ((t (:background "tomato" :foreground "white" :weight bold))))
 '(powerline-active1 ((t (:background "gray95"))))
 '(powerline-active2 ((t (:background "gray95"))))
 '(powerline-inactive0 ((t (:background "gray98"))))
 '(powerline-inactive1 ((t (:background "gray98"))))
 '(powerline-inactive2 ((t (:background "gray98"))))
 '(rjsx-attr ((t (:inherit rjsx-tag :weight normal))))
 '(rjsx-tag ((t (:foreground "dim gray" :weight bold))))
 '(rjsx-tag-bracket-face ((t (:inherit rjsx-tag))))
 '(rjsx-text ((t nil)))
 '(term ((t (:background "black" :foreground "white"))))
 '(term-bold ((t (:background "black" :foreground "white" :weight bold))))
 '(term-color-blue ((t (:background "DeepSkyBlue4" :foreground "DeepSkyBlue4")))))


;;; key commands


;; Ctrl-Backspace -> delete a word instead of killing it
(global-set-key [C-backspace] 'backward-delete-word)
;; Ctrl-Delete -> forward-delete a word instead of killing it
(global-set-key [C-delete] 'delete-word)
;; Ctrl-Tab -> next window
(global-set-key [C-tab] 'other-window)
;; Ctrl-Shift-Tab -> previous window
(global-set-key [C-S-iso-lefttab]
                (lambda ()
                  (interactive)
                  (other-window -1)))
;; Ctrl-PgDn -> next window
(global-set-key [C-next] 'other-window)
;; Ctrl-PgUp -> previous window
(global-set-key [C-prior]
                (lambda ()
                  (interactive)
                  (other-window -1)))
;; Ctrl-a -> select entire buffer
(global-set-key (kbd "C-a") 'mark-whole-buffer)
;; use useful Flycheck key bindings in Flymake
(define-key flymake-mode-map (kbd "C-c ! n") 'flymake-goto-next-error)
(define-key flymake-mode-map (kbd "C-c ! p") 'flymake-goto-prev-error)
;; keyboard command to force auto-completion
(define-key company-mode-map (kbd "M-/") 'company-complete)
;; I don't use this
(global-set-key (kbd "C-x C-k") nil)


;;; post-init


(add-hook 'after-init-hook
          (lambda ()
            (auto-compression-mode -1)
            (auto-encryption-mode -1)
            (blink-cursor-mode -1)
            (file-name-shadow-mode -1)
            (global-auto-composition-mode -1)
            (package-refresh-contents t)
            ;; keep me last
            (message "startup time: %s" (emacs-init-time))))

(provide 'emacs)
;;; .emacs ends here
