$(function() {
  var $form = $('#payment-form');
  $form.submit(function(event) {
    // Disable the submit button to prevent repeated clicks:
    $form.find('.submit').prop('disabled', true);

    // Request a source from Stripe:
    Stripe.source.create({
      type: 'card',
      card: {
        number: $('#card-number').val(),
        cvc: $('#card-cvc').val(),
        exp_month: $('#card-expiry-month').val(),
        exp_year: $('#card-expiry-year').val()
      }
    }, stripeResponseHandler);

    return false;
  });
});

function stripeResponseHandler(status, response) {
  // Grab the form:
  var $form = $('#payment-form');

  if (response.error) { // Problem!
    // Show the errors on the form:
    $form.find('.payment-errors').text(response.error.message);
    $form.find('.submit').prop('disabled', false); // Re-enable submission

  } else { // Token was created!

    // Get the source ID:
    var source = response.id;

    // Insert the source into the form so it gets submitted to the server:
    $form.append($('<input type="hidden" name="source" />').val(source));

    // Submit the form:
    $form.get(0).submit();
  }
};

function stripePoll(source, client_secret) {
  Stripe.source.poll(source, client_secret, function(status, source) {
    // `source`: is the source object.
    // `status`: is the HTTP status. if non 200, an error occured
    //          and the poll is canceled.

    // This handler is called as soon as the source is retrieved and subsequently
    // anytime the source's status (`source.status`) is updated.
    
    if (source.status === "consumed") {
      window.location.replace("/success");
    }
  })
}
