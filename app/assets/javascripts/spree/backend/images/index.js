Spree.ready(function() {
  $('#new_image_link').click(function(event) {
    event.preventDefault();

    $(this).hide();
    $('#new_image').show();
  });

  $('.scrollbar-macosx').scrollbar();

  $('.gallery-image-add').click(function() {
    openGallery(this);
  });

});

function gallery_item_clicked(obj) {
  $('#gallery .gallery-item').not(obj).removeClass('selected');
  $(obj).addClass('selected');
}

function closeGallery() {
  $('.image-picker-bg').hide();
}

function openGallery(obj) {
  varid = $(obj).attr('data-id');
  Spree.prepareImageUploader.variantId = varid;
  $('.image-picker-bg').show();
}