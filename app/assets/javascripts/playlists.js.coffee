jQuery ->
  $('#search_fullname').autocomplete
    source: $('#search_fullname').data('autocomplete-source')
