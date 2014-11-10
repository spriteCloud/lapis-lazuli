##
# All function in this file SHOULD not be used.
# There only included for backwards compatibility
#
ll = LapisLazuli::LapisLazuli.instance

##
# Creating a link for easy debugging afterwards
def create_link(name, url)
  ll.log.info("[DEPRECATED] [feature/support/transition.rb] create_link")
  #Lets just send the url without the parameters to prevent html display problems
  "<a href='#{url}' target='_blank'>#{name}</a>"
end
