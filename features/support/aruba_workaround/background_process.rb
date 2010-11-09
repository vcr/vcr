# Don't do anything--this is just here to allow aruba to run on JRuby/rbx.
# It requires background_process, but that doesn't work on JRuby/rbx.
# So on JRuby/rbx, we add this file's dir to the load path, in order to fake out aruba
# and force it to load this file instaed.
