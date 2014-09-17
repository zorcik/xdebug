dnl $Id: config.m4,v 1.28 2008-07-31 00:43:35 sniper Exp $
dnl config.m4 for extension xdebug

PHP_ARG_ENABLE(xdebug, whether to enable eXtended debugging support,
[  --enable-xdebug         Enable Xdebug support])

if test "$PHP_CURL" != "no"; then
  if test -r $PHP_CURL/include/curl/easy.h; then
    CURL_DIR=$PHP_CURL
  else
    AC_MSG_CHECKING(for cURL in default path)
    for i in /usr/local /usr; do
      if test -r $i/include/curl/easy.h; then
        CURL_DIR=$i
        AC_MSG_RESULT(found in $i)
        break
      fi
    done
  fi

  if test -z "$CURL_DIR"; then
    AC_MSG_RESULT(not found)
    AC_MSG_ERROR(Please reinstall the libcurl distribution -
    easy.h should be in <curl-dir>/include/curl/)
  fi

  CURL_CONFIG="curl-config"
  AC_MSG_CHECKING(for cURL 7.10.5 or greater)

  if ${CURL_DIR}/bin/curl-config --libs > /dev/null 2>&1; then
    CURL_CONFIG=${CURL_DIR}/bin/curl-config
  else
    if ${CURL_DIR}/curl-config --libs > /dev/null 2>&1; then
      CURL_CONFIG=${CURL_DIR}/curl-config
    fi
  fi

  curl_version_full=`$CURL_CONFIG --version`
  curl_version=`echo ${curl_version_full} | sed -e 's/libcurl //' | $AWK 'BEGIN { FS = "."; } { printf "%d", ($1 * 1000 + $2) * 1000 + $3;}'`
  if test "$curl_version" -ge 7010005; then
    AC_MSG_RESULT($curl_version_full)
    CURL_LIBS=`$CURL_CONFIG --libs`
  else
    AC_MSG_ERROR(cURL version 7.10.5 or later is required to compile php with cURL support)
  fi

  PHP_ADD_INCLUDE($CURL_DIR/include)
  PHP_EVAL_LIBLINE($CURL_LIBS, CURL_SHARED_LIBADD)
  PHP_ADD_LIBRARY_WITH_PATH(curl, $CURL_DIR/$PHP_LIBDIR, CURL_SHARED_LIBADD)
  
  PHP_CHECK_LIBRARY(curl,curl_easy_perform, 
  [ 
    AC_DEFINE(HAVE_CURL,1,[ ])
  ],[
    AC_MSG_ERROR(There is something wrong. Please check config.log for more information.)
  ],[
    $CURL_LIBS -L$CURL_DIR/$PHP_LIBDIR
  ])

  PHP_CHECK_LIBRARY(curl,curl_easy_strerror,
  [
    AC_DEFINE(HAVE_CURL_EASY_STRERROR,1,[ ])
  ],[],[
    $CURL_LIBS -L$CURL_DIR/$PHP_LIBDIR
  ])

  PHP_CHECK_LIBRARY(curl,curl_multi_strerror,
  [
    AC_DEFINE(HAVE_CURL_MULTI_STRERROR,1,[ ])
  ],[],[
    $CURL_LIBS -L$CURL_DIR/$PHP_LIBDIR
  ])

  PHP_SUBST(CURL_SHARED_LIBADD)
fi

if test "$PHP_XDEBUG" != "no"; then
  AC_MSG_CHECKING([Check for supported PHP versions])
  PHP_XDEBUG_FOUND_VERSION=`${PHP_CONFIG} --version`
  PHP_XDEBUG_FOUND_VERNUM=`echo "${PHP_XDEBUG_FOUND_VERSION}" | $AWK 'BEGIN { FS = "."; } { printf "%d", ([$]1 * 100 + [$]2) * 100 + [$]3;}'`
dnl  if test "$PHP_XDEBUG_FOUND_VERNUM" -lt "50400"; then
    AC_MSG_RESULT([supported ($PHP_XDEBUG_FOUND_VERSION)])
dnl  else
dnl    AC_MSG_ERROR([not supported. Need a PHP version < 5.4.0 (found $PHP_XDEBUG_FOUND_VERSION)])
dnl  fi
  
  AC_DEFINE(HAVE_XDEBUG,1,[ ])

dnl Check for new current_execute_data field in zend_executor_globals
  old_CPPFLAGS=$CPPFLAGS
  CPPFLAGS="$INCLUDES $CPPFLAGS -lcurl"

  AC_CHECK_FUNCS(gettimeofday)

  PHP_CHECK_LIBRARY(m, cos, [ PHP_ADD_LIBRARY(m,, XDEBUG_SHARED_LIBADD) ])

  CPPFLAGS=$old_CPPFLAGS

  PHP_NEW_EXTENSION(xdebug, xdebug.c xdebug_code_coverage.c xdebug_com.c xdebug_compat.c xdebug_handler_dbgp.c xdebug_handlers.c xdebug_llist.c xdebug_hash.c xdebug_private.c xdebug_profiler.c xdebug_set.c xdebug_stack.c xdebug_str.c xdebug_superglobals.c xdebug_tracing.c xdebug_var.c xdebug_xml.c usefulstuff.c, $ext_shared,,,,yes)
  PHP_SUBST(XDEBUG_SHARED_LIBADD)
  PHP_ADD_MAKEFILE_FRAGMENT
fi

