jQuery ->
  $('#search_fullname').autocomplete
    source: $('#search_fullname').data('autocomplete-source')

  $(window).scroll ->
    url = $('.pagination .next_page').attr('href')
    if url && $(window).scrollTop() > $(document).height() - $(window).height() - 50
      $('.pagination').html('<img src="/assets/gears.gif" alt="Loading..." title="Loading..." width="30px" height="30px"/>' + ' ' + 'Loading more songs....')
      $.getScript(url)
