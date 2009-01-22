@echo off
call git fetch origin master
call git rebase origin master
restart
