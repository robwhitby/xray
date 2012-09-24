// xray.js

$(document).ready(function() {
  // Find any profiler reports found in test divs,
  // and decorate them with hide-show controls.
  $('div.xray-test').each(
    function (i, ei) {
      $(ei).find('div.profile-report').each(
        function (j, ej) {
          var control = $(ej).find('.profile-control');
          control.click(function () {
            $(this).find('.profile-show').toggle();
            $(this).find('.profile-hide').toggle();
            $(this).parent().find('table.profile-report').toggle();
          });
          if (0 == j) control.click();
        });
    });
});

// xray.js
