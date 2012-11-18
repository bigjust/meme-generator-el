;;; meme-generator.el --- memegenerator.net's API utility
;;
;; Filename: meme-generator.el
;; Description: provides functionality for use memegenerator.net's API
;; Author: Justin Caratzas
;; Maintainer: Justin Caratzas
;; Copyright (C) 2012, Justin Caratzas, all rights reserved.
;; Version: 0.1

;; Usage:
;;
;; and now the manual bit:
;;
;; In order to create meme instances, you will need a generator id and a image id
;;
;; (meme-generator-search "fry") yields a number of results, one of which is
;; "name: Futurama Fry, generator: 305, image ID: 84688"
;;
;; then we can either (meme-generator-create-image "305" "84688" "not sure if testing api" "or actual meme")
;;
;; or add it to meme-generator-list:
;;
;; (setq meme-generator-list '(("fry" "305" "84688")
;;                             ("wonka" "599952" "2930933")
;;                             ("YUNO" "2" "166088")
;;                             ("successkid" "121" "1031")
;;                             ("mostinterestingman" "74" "2485")))
;;
;; then you can:
;;
;; (meme-generator-create ("fry" "not sure if testing api" "or actual meme")

(require 'json)

(defgroup meme-generator nil
  "memegenerator client, enables image creation for memegenerator.net"
  :prefix "meme-generator-"
  :group 'multimedia)

(defcustom meme-generator-username nil
  "username for memegenerator.net."
  :type 'string
  :group 'meme-generator)

(defcustom meme-generator-password nil
  "password for memegenerator.net."
  :type 'string
  :group 'meme-generator)

(defvar meme-generator-list nil)

(defun meme-generator-call (api-method args)
  "call memegenerator.net api API-METHOD with ARGS"
  (let* ((credentials (concat "username=" meme-generator-username "&password=" meme-generator-password))
         (url (concat "http://version1.api.memegenerator.net/" api-method "?" credentials "&" args))
         (response (url-retrieve-synchronously url)))
    (with-current-buffer response
      (goto-char (point-min))
      (re-search-forward "\n\n" nil t)
      (let ((json-object-type 'hash-table))
        (json-read-from-string
         (buffer-substring
          (point)
          (point-max)))))))

(defun parse-search-result-object (result)
  "takes result json object from and prints result names"
  (let* ((generatorID (number-to-string (gethash "generatorID" result)))
         (imageURL (gethash "imageUrl" result))
         (filename (substring imageURL (string-match "[0-9]+\.jpg" imageURL) (match-end 0)))
         (name (gethash "displayName" result))
         (imageID (substring filename (string-match "[0-9]+" filename) (match-end 0))))
    (concat "name: " name ", generator: " generatorID ", image ID: " imageID)))

;;;###autoload
(defun meme-generator-search (term)
  "Search TERM generator on meme-generator."
  (let* ((json-response (meme-generator-call "Generators_Search" (concat "q=" term)))
        (result (elt (gethash "result" json-response) 0))
        (results (mapcar 'parse-search-result-object (gethash "result" json-response))))
    (with-output-to-temp-buffer "memes"
      (mapcar '(lambda (result)
                 (print result))
              results))
    (concat (number-to-string (length results)) " results")))

(defun meme-generator-create-image (generator-id image-id text1 text2)
  "create meme-generator image instance with GENERATOR-ID, IMAGE-ID, TEXT1 and TEXT2"
  (let ((json-response (meme-generator-call "Instance_Create"
                                             (concat "generatorID=" generator-id
                                                     "&imageID=" image-id
                                                     "&text0=" text1
                                                     "&text1=" text2))))
    (gethash "instanceImageUrl" (gethash "result" json-response))))

;;;###autoload
(defun meme-generator-create (meme-name text1 text2)
  "create meme-generator image instance utilizing "
  (let ((meme-info (assoc meme-name meme-generator-list)))
    (meme-generator-create-image (cadr meme-info)
                                 (caddr meme-info)
                                 text1 text2)))


(provide 'meme-generator)
;;; meme-generator.el ends here
