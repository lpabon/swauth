#!/bin/bash

test_print()
{
    echo "--> $1"
}

fail()
{
    echo $1
    exit 1
}

test_print "Stopping swift"
swift-init main stop

test_print "Clean gluster-object"
rm -rf /mnt/gluster-object/*

test_print "Create dirs"
mkdir /mnt/gluster-object/test
mkdir /mnt/gluster-object/newaccount
mkdir /mnt/gluster-object/.auth
mkdir /mnt/gluster-object/test2

test_print "Create rings"
gluster-swift-gen-builders test test2 .auth newaccount

test_print "Starting swift"
swift-init main start

test_print "swauth prep"
swauth-prep -K swauthkey || fail "Unable to prep"

test_print "Creating tester:testing for test"
swauth-add-user -A http://127.0.0.1:8080/auth/ -K swauthkey -a test tester testing || fail "Unable to create user"

test_print "Get stat on test using tester:testing"
swift -A http://127.0.0.1:8080/auth/v1.0 -U test:tester -K testing stat || fail "Unable to get stat" 

test_print "Creating myuser:mypassword for newaccount, which automatically creates account newaccount"
swauth-add-user -A http://127.0.0.1:8080/auth/ -K swauthkey -a newaccount myuser mypassword

test_print "Get stat on newaccount myuser:mypassword"
swift -A http://127.0.0.1:8080/auth/v1.0 -U newaccount:myuser -K mypassword stat || fail "Unable to get stat" 

test_print "Get stat on test myuser:mypassword"
swift -A http://127.0.0.1:8080/auth/v1.0 -U test:myuser -K mypassword stat && fail "Able to get stat" 

test_print "Get stat on newaccount using tester:testing"
swift -A http://127.0.0.1:8080/auth/v1.0 -U newaccount:tester -K testing stat && fail "Able to get stat" 

test_print "Try to delete account newaccount, it should fail on conflict until users are deleted"
swauth-delete-account -K swauthkey newaccount && fail "Was able to delete an account which should not have been able to"

test_print "Delete the user in newaccount"
swauth-delete-user -K swauthkey newaccount myuser || fail "Unable to delete myuser in newaccount"

test_print "We deleted myuser, verify unauthorized access"
swift -A http://127.0.0.1:8080/auth/v1.0 -U newaccount:myuser -K mypassword stat && fail "Unable to get stat" 

test_print "Delete account newaccount"
swauth-delete-account -K swauthkey newaccount || fail "Unable to delete account"

echo "All tests passed"
