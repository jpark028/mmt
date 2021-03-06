$(document).ready ->
  # Disable toggle
  $('.eui-accordion__header.disable-toggle').unbind('click');

  # Open accordion based on URL hash
  if window.location.hash
    hash = window.location.hash.substring(1)
    $body = $(document.getElementById(hash))
    .find('.eui-accordion__body').first()

    if $body.parent().hasClass('eui-accordion')
      if $body.parent().find('.disable-toggle').length == 0
        $body.slideToggle 'fast', ->
          $(this).parent().toggleClass 'is-closed'
          $('html, body').animate {
            scrollTop: $(this).parent().offset().top
          }, 500

  $('.expand-accordions').on 'click', ->
    $('.eui-accordion.is-closed').removeClass('is-closed')
    $('.eui-accordion__body').slideDown('fast')
    $('.expand-accordions').addClass('is-invisible')
    $('.collapse-accordions').removeClass('is-invisible')

  $('.collapse-accordions').on 'click', ->
    $('.eui-accordion').addClass('is-closed')
    $('.eui-accordion__body').slideUp('fast')
    $('.collapse-accordions').addClass('is-invisible')
    $('.expand-accordions').removeClass('is-invisible')

  # Change Expand/Collapse All link if all accordions on page are collapsed or expanded
  $('.eui-accordion__header').on 'click', ->
    # We don't really care about every accordion on the page for this, just the top level accordions, or fieldset.eui-accordion

    # if all accordions are closed
    if $('fieldset.eui-accordion.is-closed').length == $('fieldset.eui-accordion').length
      $('.collapse-accordions').addClass('is-invisible')
      $('.expand-accordions').removeClass('is-invisible')

    # if all accordions are open
    if $('fieldset.eui-accordion.is-closed').length == 0
      $('.collapse-accordions').removeClass('is-invisible')
      $('.expand-accordions').addClass('is-invisible')
