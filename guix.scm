(use-modules (guix packages))
(use-modules (guix utils))
(use-modules (guix gexp))
(use-modules (gnu packages))
(use-modules (gnu packages bash))
(use-modules (gnu packages imagemagick))
(use-modules (gnu packages ghostscript))
(use-modules (gnu packages pdf))
 (use-modules (guix build-system copy))
 (use-modules (guix git-download))
 (use-modules ((guix licenses) #:prefix license:))
 (use-modules (ice-9 popen))
 (use-modules (ice-9 textual-ports))
 (use-modules (ice-9 rdelim))

(define %source-dir (dirname (current-filename)))

(define %git-commit
  (read-string (open-pipe "git show HEAD | head -1 | cut -d ' ' -f2" OPEN_READ)))

(define (skip-git-and-build-directory file stat)
  "Skip the `.git` and `build` and `guix_profile` directory when collecting the sources."
  (let ((name (basename file)))
    (not (or (string=? name ".git")
             (string=? name "build")
             (string-prefix? "guix_profile" name)))))

(define *version* (call-with-input-file "VERSION"
                    get-string-all))

(define-public falsisign
  (package
   (name "falsisign")
   (version (git-version *version* "HEAD" %git-commit))
   (source (local-file %source-dir
                       #:recursive? #t
                       #:select? skip-git-and-build-directory))
   (propagated-inputs (list bash imagemagick ghostscript poppler))
   (build-system copy-build-system)
   (arguments
    `(#:install-plan '(
                       ("./falsisign.sh" "bin/falsisign")
                       ("./signdiv.sh" "bin/signdiv")
                       )
      #:phases
      (modify-phases %standard-phases
                     (add-before
                      'build 'check
                      (lambda* (#:key outputs #:allow-other-keys)
                                 (invoke "make" "test")
                                 #t)))
      ))
   (synopsis "Later")
   (description
    "Later")
   (home-page "Later")
   (license license:agpl3+)))

falsisign
