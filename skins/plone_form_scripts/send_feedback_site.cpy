## Controller Python Script "send_feedback_site"
##bind container=container
##bind context=context
##bind namespace=
##bind script=script
##bind state=state
##bind subpath=traverse_subpath
##parameters=
##title=Send feedback to portal administrator
##
REQUEST=context.REQUEST

from Products.CMFPlone.utils import transaction_note
from Products.CMFCore.utils import getToolByName
from ZODB.POSException import ConflictError

##
## This may change depending on the called (portal_feedback or author)
state_success = "success"
state_failure = "failure"


plone_utils = getToolByName(context, 'plone_utils')
mtool = getToolByName(context, 'portal_membership')

site_properties = getToolByName(context, 'portal_properties').site_properties

## make these arguments?
subject = REQUEST.get('subject', '')
message = REQUEST.get('message', '')
sender_from_address = REQUEST.get('sender_from_address', '')
sender_fullname = REQUEST.get('sender_fullname', '')

url     = context.portal_url

site_properties = getToolByName(context, 'portal_properties').site_properties
send_to_address = site_properties.email_from_address
envelope_from = site_properties.email_from_address

state.set(status=state_success) ## until proven otherwise

host = context.MailHost # plone_utils.getMailHost() (is private)
encoding = plone_utils.getSiteEncoding()

variables = {'sender_from_address' : sender_from_address,
             'sender_fullname'     : sender_fullname,             
             'url'                 : url,
             'subject'             : subject,
             'message'             : message
             }

try:
    message = context.site_feedback_template(context, **variables)
    result = host.secureSend(message, send_to_address, envelope_from, subject=subject, subtype='plain', charset=encoding, debug=False, From=sender_from_address)
except ConflictError:
    raise
except: # TODO Too many things could possibly go wrong. So we catch all.
    exception = context.plone_utils.exceptionString()
    message = context.translate("Unable to send mail: ${exception}",
                                {'exception': exception})
    return state.set(status=state_failure, portal_status_message=message)


## clear request variables so form is cleared as well
REQUEST.set('message', None)
REQUEST.set('subject', None)
REQUEST.set('sender_from_address', None)
REQUEST.set('sender_fullname', None)

state.set(portal_status_message='Mail sent.')
return state