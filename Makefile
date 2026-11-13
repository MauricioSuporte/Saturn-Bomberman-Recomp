# Saturn Bomberman Recomp: a game repository for the satrecomp toolkit.
# The toolkit is a copy in satrecomp/ (made by its tools/sync-toolkit.sh); to work on the toolkit
# itself, build against a clone of it: make SR=../satrecomp
GAME ?= saturn_bomberman
SR ?= satrecomp
include $(SR)/build.mk
