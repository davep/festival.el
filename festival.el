;;; festival.el --- Emacs interface into festival.
;; Copyright 1999-2017 by Dave Pearson <davep@davep.org>

;; Author: Dave Pearson <davep@davep.org>
;; Version: 1.7
;; Keywords: games, speech
;; URL: https://github.com/davep/festival.el

;; This program is free software: you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by the
;; Free Software Foundation, either version 3 of the License, or (at your
;; option) any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
;; Public License for more details.
;;
;; You should have received a copy of the GNU General Public License along
;; with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; festival.el provides a simple interface into the festival speech
;; synthesis program <URL:http://www.cstr.ed.ac.uk/projects/festival/> from
;; Emacs Lisp.
;;
;; BTW, it was only once I'd more or less finished writing the first version
;; of this that I noticed that a festival.el comes with festival itself
;; (yeah, I know, I should spend more time examining the contents of
;; software packages). As it is, I decided to press on with this anyway
;; because I'd done a couple of different things and, more importantly, I
;; was having far too much fun.

;;; Code:

;; Customize options.

(defgroup festival nil
  "festival.el - Interface to the festival speech synthesis program."
  :group 'external
  :prefix "festival-")

(defcustom festival-program "/usr/bin/festival"
  "Location of the festival program."
  :type  '(file :must-match t)
  :group 'festival)

(defcustom festival-buffer "*festival*"
  "Name of buffer to attach to the festival process.

Set this to NIL if you don't want a buffer created."
  :type  '(choice
           (string :tag "Buffer name")
           (const  :tag "Don't attach a buffer" nil))
  :group 'festival)

(defcustom festival-default-audio-mode 'async
  "Default audio_mode for a new festival process."
  :type  '(choice (const async)
           (const sync)
           (const close)
           (const shutup)
           (const query))
  :group 'festival)

(defcustom festival-default-voice 'festival-voice-english-male
  "Default voice."
  :type  '(choice
           (const :tag "English, male" festival-voice-english-male)
           (const :tag "US, male"      festival-voice-US-male))
  :group 'festival)

(defcustom festival-voices-alist '(("english-male" . festival-voice-english-male)
                                   ("us-male"      . festival-voice-US-male))
  "An alist of voice names to set-function mappings."
  :type  '(repeat (cons string function))
  :group 'festival)

(defcustom festival-auto-start t
  "Should festival start when any of the functions are called?"
  :type  'boolean
  :group 'festival)

;; Non-customize variables.

(defvar festival-process nil
  "Process handle for the festival program.")

;; Main code.

;;;###autoload
(defun festival-start ()
  "Start a festival process. If a process is already running, this is a no-op."
  (interactive)
  (let ((proc-name "festival"))
    (unless (get-process proc-name)
      (setq festival-process (start-process proc-name festival-buffer festival-program))
      (set-process-query-on-exit-flag festival-process nil)
      (festival-audio-mode festival-default-audio-mode)
      (funcall festival-default-voice))))

(defun festival-stop ()
  "Stop a festival process. If there is no process running this is a no-op."
  (interactive)
  (when (processp festival-process)
    (kill-process festival-process))
  (setq festival-process nil))

(defun festival-p ()
  "Return t if a festival process is running, nil if not.

Note that if `festival-auto-start' is set to t this function will always
return t and, if a festival proecss isn't running, it will start one for
you."
  (let ((festivalp (processp festival-process)))
    (when (and (not festivalp) festival-auto-start)
      (festival-start)
      (setq festivalp t))
    festivalp))

(defun festival-send (format &rest args)
  "Send text to the festival process, FORMAT is a `format' format string.

ARGS is the arguments passed to `format'."
  (when (festival-p)
    (process-send-string festival-process (apply #'format format args))))

;;;###autoload
(defun festival-audio-mode (mode)
  "Set the festival audio mode to MODE.

See the festival documentation for a list of valid modes."
  (festival-send "(audio_mode '%s)\n" mode))

;;;###autoload
(defun festival-say (text)
  "Say TEXT via the festival process."
  (interactive "sText: ")
  (festival-send "(SayText \"%s\")\n" text))

;;;###autoload
(defun festival-read-file (file)
  "Get festival to read the contents of FILE."
  (interactive "fFile: ")
  (festival-send "(tts_file \"%s\")\n" (expand-file-name file)))

(defun festival-read-region-in-buffer (buffer start end)
  "Read region from BUFFER bounding START to END."
  (when (festival-p)
    (let ((temp-file (make-temp-name "/tmp/emacs-festival-")))
      (with-current-buffer buffer
        (write-region start end temp-file nil 0)
        (festival-send "(progn (tts_file \"%s\") (delete-file \"%s\"))\n"
                       temp-file temp-file)))))

;;;###autoload
(defun festival-read-buffer (buffer)
  "Read the contents of BUFFER."
  (interactive "bBuffer: ")
  (with-current-buffer (get-buffer buffer)
    (festival-read-region-in-buffer (current-buffer) (point-min) (point-max))))

;;;###autoload
(defun festival-read-region (start end)
  "Read a region bounding START to END from the `current-buffer'."
  (interactive "r")
  (festival-read-region-in-buffer (current-buffer) start end))

;;;###autoload
(defun festival-intro ()
  "Fire off the festival intro."
  (interactive)
  (festival-send "(intro)\n"))

;; Functions for selecting various voices.

;;;###autoload
(defun festival-voice-english-male ()
  "Choose an male English voice."
  (interactive)
  (festival-send "(voice.select 'rab_diphone)\n"))

;;;###autoload
(defun festival-voice-US-male ()
  "Choose a male US voice."
  (interactive)
  (festival-send "(voice.select 'ked_diphone)\n"))

;;;###autoload
(defun festival-voice (voice-name)
  "Interactively set the voice to VOICE-NAME."
  (interactive (list (completing-read "Voice: " festival-voices-alist nil t)))
  (funcall (cdr (assoc voice-name festival-voices-alist))))

;; Functions for hooking into other parts of emacs and making them talk.

;;;###autoload
(defun festival-hook-doctor ()
  "Hook `doctor' so that the doctor talks via festival."
  (interactive)
  (defadvice doctor-txtype (before festival-doctor-txtype (ans) activate)
    (festival-say ans)))

(defun festival-unhook-doctor ()
  "Undo the hook set by `festival-hook-doctor'."
  (interactive)
  (ad-remove-advice 'doctor-txtype 'before 'festival-doctor-txtype)
  (ad-update 'doctor-txtype))

;;;###autoload
(defun festival-hook-message ()
  "Hook `message' so that all passed text is spoken."
  (interactive)
  (defadvice message (before festival-message (format-string &rest objects) activate)
    (festival-say (apply #'format format-string objects))))

(defun festival-unhook-message ()
  "Undo the hook set by `festival-hook-message'."
  (interactive)
  (ad-remove-advice 'message 'before 'festival-message)
  (ad-update 'message))

;;;###autoload
(defun festival-hook-error ()
  "Hook `error' so that all passed text is spoken."
  (interactive)
  (defadvice error (before festival-error (format-string &rest args) activate)
    (festival-say (apply #'format format-string args))))

(defun festival-unhook-error ()
  "Undo the hook set by `festival-hook-error'."
  (interactive)
  (ad-remove-advice 'error 'before 'festival-error)
  (ad-update 'error))

;;;###autoload
(defun festival-describe-function (f)
  "Read the description of function F.

Talking version of `describe-function'."
  (interactive "aDescribe function: ")
  (with-temp-buffer
    (insert (documentation f))
    (festival-read-buffer (current-buffer))))

;;;###autoload
(defun festival-spook ()
  "Feed those hidden microphones."
  (interactive)
  (with-temp-buffer
    (spook)
    (festival-read-buffer (current-buffer))))

(provide 'festival)

;;; festival.el ends here
