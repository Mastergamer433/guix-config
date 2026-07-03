(define-module (config packages hyprland)
  #:use-module (guix packages)
  #:use-module ((guix licenses)
		#:prefix license:)
  #:use-module (guix gexp)
  #:use-module (guix build-system gnu)
  #:use-module (gnu packages lua))

(define-public my-hypr-config
	       (package
		 (name "my-hypr-config")
		 (version "0.1")
		 (source (local-file "./hypr-config"
				     #:recursive? #t))
		 (build-system gnu-build-system)
		 (native-inputs (list fennel))
		 (arguments
		   (list
		     #:tests? #f
		     #:phases
		     #~(modify-phases %standard-phases
				      (delete 'configure)
				      (delete 'check)

				      (replace 'build
					       (lambda _
						 (use-modules (guix build utils)
							      (ice-9 ftw)
							      (srfi srfi-1))

						 (define (strip-prefix path prefix)
						   (if (string-prefix? prefix path)
						     (substring path (string-length prefix))
						     path))

						 (define (fnl->lua path)
						   (let* ((no-prefix (strip-prefix path "./src/"))
							  (no-ext (string-drop-right no-prefix 4)))
							  (string-append "build/" no-ext ".lua")))


								       
						 (mkdir-p "build")

						 (for-each
						   (lambda (file)
						     (when (string-suffix? ".fnl" file)
						       (let* ((out (fnl->lua file)))
							 (mkdir-p (dirname out))
							 
							 (with-output-to-file out
									      (lambda ()
							 (invoke "fennel"
								 "--compile"
								 file))))))
						   (find-files "." "\\.fnl$"))))


				      (replace 'install
					       (lambda _
						 (use-modules (guix build utils))
						 (let ((out (string-append #$output "/share/hypr")))
						   (mkdir-p out)
						   (copy-recursively "build" out)))))))

		   (synopsis "My Hyprland configuration")
		   (description "My Hyprland config")
		   (home-page "")
		   (license #f)))


