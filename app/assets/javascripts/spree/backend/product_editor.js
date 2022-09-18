var productImageArrayIndex = 1;

function addMoreProductImageRow() {
  var html = $("#new_product_image_row").html();
  $(".product-image-row").parent().append("<tr id='new_product_image_row_" + productImageArrayIndex + "'>" + html + "</tr>");
  productImageArrayIndex++;
}

function addMoreProductPropertyRow() {
  var firstRow = $("#spree_new_product_property");
  var html = firstRow.html().replace(/\[0\]/g, '[' + firstRow.parent().children().size() +']' );
  var newRow = firstRow.parent().append("<tr class='product_property fields' data-hook='product_property'>" + html + '</tr>');
}

function removeOptionMappingRow(el) {

}

var currenyPriceArrayIndex = 1;
function updateCurrencyPriceField() {
  if ($(this).val() == '') {
    /* var inputGroup = $(this).parent();
     if ( !inputGroup.hasClass('input-group') ) {
     inputGroup = inputGroup.parent();
     }
     inputGroup.parent().fadeOut().remove();
     $(this).remove(); */
  } else {
    addCurrencyPriceField();
    refreshCurrencySelectList();
    setToUpdateCurrencyPriceField();
  }
}

function addCurrencyPriceField() {
  var html = $("#new_currency_price_wrapper").html();
  $("#curreny_prices_list").append("<div class='col-6 mb-2' id='new_currency_price_wrapper_" + currenyPriceArrayIndex + "'>" + html + "</div>");
  currenyPriceArrayIndex++;
  $("#curreny_prices_list > div:last-child input[type='text']").focus();
}

function refreshCurrencySelectList() {
  var currencyTypeList = $("#curreny_prices_list *[data-type='currency']");
  if (currencyTypeList.length > 1) {
    var existingValues = [];
    currencyTypeList.each(function(index){
      if($(this).val() != ""){ existingValues.push( $(this).val() ); }
    });
    $("#curreny_prices_list select[data-type='currency']").each(function(index){
      var selectField = $(this);
      var siblingAmountField =  $( selectField.siblings("input[type='text']")[0] );
      if (siblingAmountField != null && $(siblingAmountField).val() == '') {
        selectField.children().each(function(cindex){
          if (existingValues.includes( $(this).val() ) ) {
            $(this).remove();
          }
        });
      }
    });
  }
}

function setToUpdateCurrencyPriceField() {
  $("input[name='product[price_attributes][][amount]']").on('change', updateCurrencyPriceField);
}

picker = {};

function loadColorPicker() {
  var p = $('.color-picker-palette')[0]; // put color picker panel in the second `<p>` element
  if (p == undefined)
    return;

  picker = new CP($('#colorpicker_value')[0], false, p);

  picker.on("change", function(color) {
    this.source.value = '#' + color;

    $('.color-picker-preview .m-auto').empty();
    colorname = 'New Color';
    colorid = '';
    colorvalue = '#' + color;
    el = makeColorBox(colorid, colorvalue, colorname);

    $('.color-picker-preview .m-auto').append(el);
    $('.color-picker-preview .m-auto .color-box').addClass('readonly');
  });

  return picker;
}

String.prototype.replaceAll = function(search, replacement) {
  var target = this;
  return target.replace(new RegExp(search, 'g'), replacement);
};

const colorbox_template1 = '<div class="color-wrapper"><div class="color-box option-value-btn" onclick="toggleSelection(this)" style="border-color: black;" data="colorid" data-name="colorname" data-value="colorvalue"><svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" style="isolation:isolate" viewBox="0 0 50 50" width="50pt" height="50pt" class="color-value-button"><defs><clipPath id="_clipPath_tb3pgmzt71gZgjRUMFz7kla7XsGZguKQ"><rect width="50" height="50"></rect></clipPath></defs><g clip-path="url(#_clipPath_tb3pgmzt71gZgjRUMFz7kla7XsGZguKQ)"><mask id="_mask_oCFp9qrrrQeffIoCHuWrFndlIZ6tpd83"></mask><circle vector-effect="non-scaling-stroke" cx="25" cy="25" r="25" fill="none" mask="url(#_mask_oCFp9qrrrQeffIoCHuWrFndlIZ6tpd83)" stroke-width="6" stroke="color1" stroke-linejoin="miter" stroke-linecap="square" stroke-miterlimit="3"></circle><circle vector-effect="non-scaling-stroke" cx="25" cy="25" r="25" fill="none"></circle><path d=" M 35.432 11.739 C 32.56 9.476 28.937 8.125 25 8.125 C 15.686 8.125 8.125 15.686 8.125 25 C 8.125 28.937 9.476 32.56 11.739 35.432 L 35.432 11.739 Z  M 38.261 14.568 C 40.524 17.44 41.875 21.063 41.875 25 C 41.875 34.314 34.314 41.875 25 41.875 C 21.063 41.875 17.44 40.524 14.568 38.261 L 38.261 14.568 Z " fill-rule="evenodd" fill="color1"></path><circle vector-effect="non-scaling-stroke" cx="24.999999999999996" cy="24.999999999999996" r="16.875000000000007" fill="color1"></circle></g></svg></div></div>';
const colorbox_template2 = '<div class="color-wrapper"><div class="color-box option-value-btn" onclick="toggleSelection(this)" style="border-color: black;" data="colorid" data-name="colorname" data-value="colorvalue"><svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" style="isolation:isolate" viewBox="0 0 50 50" width="50pt" height="50pt"><defs><clipPath id="_clipPath_JuHM8qzruj2aKf5MW2NorbnVxhGKkLBN"><rect width="50" height="50"></rect></clipPath></defs><g clip-path="url(#_clipPath_JuHM8qzruj2aKf5MW2NorbnVxhGKkLBN)"><mask id="_mask_9uwPSRnBTIHwKN84BkS867cKeriONcUn"></mask><circle vector-effect="non-scaling-stroke" cx="25" cy="25" r="25" fill="none" mask="url(#_mask_9uwPSRnBTIHwKN84BkS867cKeriONcUn)" stroke-width="6" stroke="color1" stroke-linejoin="miter" stroke-linecap="square" stroke-miterlimit="3"></circle><circle vector-effect="non-scaling-stroke" cx="25" cy="25" r="25" fill="none"></circle><path d=" M 35.432 11.739 C 32.56 9.476 28.937 8.125 25 8.125 C 15.686 8.125 8.125 15.686 8.125 25 C 8.125 28.937 9.476 32.56 11.739 35.432 L 35.432 11.739 Z  M 38.261 14.568 C 40.524 17.44 41.875 21.063 41.875 25 C 41.875 34.314 34.314 41.875 25 41.875 C 21.063 41.875 17.44 40.524 14.568 38.261 L 38.261 14.568 Z " fill-rule="evenodd" fill="color2"></path><path d=" M 38.261 14.568 C 40.524 17.44 41.875 21.063 41.875 25 C 41.875 34.314 34.314 41.875 25 41.875 C 21.063 41.875 17.44 40.524 14.568 38.261 L 38.261 14.568 L 38.261 14.568 Z " fill-rule="evenodd" fill="color1"></path></g></svg></div></div>';
const t_colorbox_template1 = '<div class="variant-one-box"><div class="color-wrapper"><div class="color-box option-value-btn" onclick="toggleSelection(this)" style="border-color: black;" data="colorid" data-name="colorname" data-value="colorvalue"><svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" style="isolation:isolate" viewBox="0 0 50 50" width="50pt" height="50pt" class="color-value-button"><defs><clipPath id="_clipPath_tb3pgmzt71gZgjRUMFz7kla7XsGZguKQ"><rect width="50" height="50"></rect></clipPath></defs><g clip-path="url(#_clipPath_tb3pgmzt71gZgjRUMFz7kla7XsGZguKQ)"><mask id="_mask_oCFp9qrrrQeffIoCHuWrFndlIZ6tpd83"></mask><circle vector-effect="non-scaling-stroke" cx="25" cy="25" r="25" fill="none" mask="url(#_mask_oCFp9qrrrQeffIoCHuWrFndlIZ6tpd83)" stroke-width="6" stroke="color1" stroke-linejoin="miter" stroke-linecap="square" stroke-miterlimit="3"></circle><circle vector-effect="non-scaling-stroke" cx="25" cy="25" r="25" fill="none"></circle><path d=" M 35.432 11.739 C 32.56 9.476 28.937 8.125 25 8.125 C 15.686 8.125 8.125 15.686 8.125 25 C 8.125 28.937 9.476 32.56 11.739 35.432 L 35.432 11.739 Z  M 38.261 14.568 C 40.524 17.44 41.875 21.063 41.875 25 C 41.875 34.314 34.314 41.875 25 41.875 C 21.063 41.875 17.44 40.524 14.568 38.261 L 38.261 14.568 Z " fill-rule="evenodd" fill="color1"></path><circle vector-effect="non-scaling-stroke" cx="24.999999999999996" cy="24.999999999999996" r="16.875000000000007" fill="color1"></circle></g></svg></div>	</div><div class="variant-description box-shadow"><div class="variant-heading"><span>varname</span></div><div class="variant-body"><input class="variant-name" readonly="readonly" value="colorname"></div><div class="variant-footer"><div class="cover"></div></div></div></div>';
const t_colorbox_template2 = '<div class="variant-one-box"><div class="color-wrapper"><div class="color-box option-value-btn" onclick="toggleSelection(this)" style="border-color: black;" data="colorid" data-name="colorname" data-value="colorvalue"><svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" style="isolation:isolate" viewBox="0 0 50 50" width="50pt" height="50pt"><defs><clipPath id="_clipPath_JuHM8qzruj2aKf5MW2NorbnVxhGKkLBN"><rect width="50" height="50"></rect></clipPath></defs><g clip-path="url(#_clipPath_JuHM8qzruj2aKf5MW2NorbnVxhGKkLBN)"><mask id="_mask_9uwPSRnBTIHwKN84BkS867cKeriONcUn"></mask><circle vector-effect="non-scaling-stroke" cx="25" cy="25" r="25" fill="none" mask="url(#_mask_9uwPSRnBTIHwKN84BkS867cKeriONcUn)" stroke-width="6" stroke="color1" stroke-linejoin="miter" stroke-linecap="square" stroke-miterlimit="3"></circle><circle vector-effect="non-scaling-stroke" cx="25" cy="25" r="25" fill="none"></circle><path d=" M 35.432 11.739 C 32.56 9.476 28.937 8.125 25 8.125 C 15.686 8.125 8.125 15.686 8.125 25 C 8.125 28.937 9.476 32.56 11.739 35.432 L 35.432 11.739 Z  M 38.261 14.568 C 40.524 17.44 41.875 21.063 41.875 25 C 41.875 34.314 34.314 41.875 25 41.875 C 21.063 41.875 17.44 40.524 14.568 38.261 L 38.261 14.568 Z " fill-rule="evenodd" fill="color2"></path><path d=" M 38.261 14.568 C 40.524 17.44 41.875 21.063 41.875 25 C 41.875 34.314 34.314 41.875 25 41.875 C 21.063 41.875 17.44 40.524 14.568 38.261 L 38.261 14.568 L 38.261 14.568 Z " fill-rule="evenodd" fill="color1"></path></g></svg></div></div><div class="variant-description box-shadow"><div class="variant-heading"><span>varname</span></div><div class="variant-body"><input class="variant-name" readonly="readonly" value="colorname"></div><div class="variant-footer"><div class="cover"></div></div></div></div>';

function makeColorBox(colorid, colorvalue, colorname) {
  colors = colorvalue.split(',');
  color1 = colors[0];
  color2 = colors.length > 1 ? colors[1] : ''
  if (color2 == '') {
    el = colorbox_template1;
    el = el.replaceAll('color1', color1);
  } else {
    el = colorbox_template2;
    el = el.replaceAll('color1', color1);
    el = el.replaceAll('color2', color2);
  }
  el = el.replaceAll('colorid', colorid);
  el = el.replaceAll('colorvalue', colorvalue);
  el = el.replaceAll('colorname', colorname);
  return el;
}

function makeTippedColorBox(colorid, colorvalue, colorname) {
  colors = colorvalue.split(',');
  color1 = colors[0];
  color2 = colors.length > 1 ? colors[1] : ''
  if (color2 == '') {
    el = t_colorbox_template1;
    el = el.replaceAll('color1', color1);
  } else {
    el = t_colorbox_template2;
    el = el.replaceAll('color1', color1);
    el = el.replaceAll('color2', color2);
  }
  el = el.replaceAll('colorid', colorid);
  el = el.replaceAll('colorvalue', colorvalue);
  el = el.replaceAll('colorname', colorname);
  el = el.replaceAll('variantname', colorname);
  return el;
}

Spree.ready(function() {

  sizes = [
    'US 6.0 / EU 38.5 / CM 24',
    'US 6.5 / EU 39.0 / CM 24.5',
    'US 7.0 / EU 39.5 / CM 25',
    'US 7.5 / EU 40.0 / CM 25.5',
    'US 8.0 / EU 40.5 / CM 26',
    'US 8.5 / EU 41.0 / CM 26.5'
  ];

  $('.variant-box .color-box').click(function(){
    $(this).toggleClass('selected');
  });

  $('.variant-option-box .color-box').click(function(){
    $(this).toggleClass('selected');
  });

  selections = [];

  function paletteColor_clicked() {
    if ($(this).hasClass('selected')) {
      $(this).toggleClass('selected');
      for( var i = 0; i < selections.length; i++){
        if ( selections[i].colorid == $(this).attr('data')) {
          selections.splice(i, 1);
        }
     }
      drawPreview();
    } else if (selections.length < 2) {
      $(this).toggleClass('selected');
      selections.push({
        colorname: $(this).attr('data-name'),
        colorid: $(this).attr('data'),
        colorvalue: $(this).attr('data-value'),
        variantname: $(this).attr('data-value')
      });
      drawPreview();
    }
  }


  function drawPreview() {
    if (selections.length == 0) return;

    el = '';

    $('.color-palette-preview .m-auto').empty();
    if (selections.length > 1) {
      colorname = selections[0].colorname + ' / ' + selections[1].colorname;
      colorid = '';                         // ------------------> we need to get this value from server (new color combination id or existing id)
      colorvalue = selections[0].colorvalue + ',' + selections[1].colorvalue;
      el = makeColorBox(colorid, colorvalue, colorname);
    } else {
      colorname = selections[0].colorname;
      colorid = selections[0].colorid;
      colorvalue = selections[0].colorvalue;
      el = makeColorBox(colorid, colorvalue, colorname);
    }
    $('.color-palette-preview .m-auto').append(el);
    $('.color-palette-preview .m-auto .color-box').addClass('readonly');
  }

  $('.color-palette .color-box').click(paletteColor_clicked);

  $('.color-palette-preview .reverse .btn').click(function() {
    selections.reverse();
    drawPreview();
  });

  $('.color-palette-wrapper .confirm .btn').click(function() {
    paletteValue = $('.color-palette-preview .color-box');
    colorname = paletteValue.attr('data-name');
    colorid = paletteValue.attr('data');
    colorvalue = paletteValue.attr('data-value');
    el = makeTippedColorBox(colorid, colorvalue, colorname);
    $('.variant-box-body').append(el);
    ;$('.color-picker').toggleClass('d-flex')
  })

  $('.color-picker-wrapper .confirm .btn').click(function() {
    colorname = $('#color_name').val();
    colorid = '';
    colorvalue = $('#colorpicker_value').val();
    el = makeColorBox(colorid, colorvalue, colorname);
    addBtn = $('.color-palette .color-wrapper:last-child');
    // console.log(addBtn);
    newColorBtnWraper = $(el).insertBefore(addBtn);
    newColorBtn = newColorBtnWraper.find('.color-box');
    newColorBtn.unbind('click');
    newColorBtn[0].onclick = '';
    newColorBtn.click(paletteColor_clicked);

    $('.color-picker-wrapper').hide();
    $('.color-palette-wrapper').show();

  });

  $('.color-palette-heading .close-btn').click(function() {
    $('.color-picker').toggleClass('d-flex');
  });

  $('.color-picker-heading .close-btn').click(function() {
    $('.color-picker-wrapper').hide();
    $('.color-palette-wrapper').show();
  });

  $('.add-variant').click(function(){
    $('.color-palette .color-box').removeClass('selected');
    $('.color-picker').toggleClass('d-flex');

    selections = [];
  });

  $('.color-add').click(function() {
    $('.color-palette-wrapper').hide();
    $('.color-picker-wrapper').show();

    picker.enter();
  });

  loadColorPicker();

  $('#product_category').change(function() {
    $.ajax({
      url: '/related_option_types/taxon/' + $('#product_category').val() + '.json?token=' + Spree.api_key,
      success: function(result) {
        console.log(result);
      },
      dataType: 'json'
    });
  });

  $('.confirm-variant').click(function(){
    selected = $('.variant-box .selected');
    $('.sizes-box thead').empty();
    $('.sizes-box thead').append('<th></th>');
    selected.each(function(idx){
      e = $(this);
      colorvalue = e.attr('data-value');
      colors = colorvalue.split(',');
      colorname = e.attr('data-name');
      colorid = e.attr('data');

      el = makeColorBox(colorid, colorvalue, colorname);

      $('.sizes-box thead').append('<th class="selected" onclick="checkColumn(this)" data-idx="' + (idx + 2) + '">' + el + '</th>');
    });
    $('.sizes-box thead').append('<th></th>');

    $('.sizes-box tbody').empty();
    sizes.forEach(function(s) {
      el = '<tr><td><div class="option-box d-flex jc-sb"><div>' + s + '</div><a class="option-remove" onclick="removeRow(this)"></a></div></td>';
      selected.each(function(e){
        el += '<td class="fs-25"><div class="checkbox"><span class="cr no-border" onclick="checkCell(this)"><input type="checkbox"><i class="cr-icon fa fa-check"></i></span></div></td>';
      });
      el += '<td></td>';
      el += '</tr>';
      $('.sizes-box tbody').append(el);
    });

    w = 200 + 55 * selected.length + 55;
    $('.variant-option-box').css('width', w + 'px');
  });

  $('.size-box thead th.selected').click(function() {

  });

  $('.sizes-box .add-all').click(function() {
    $('.sizes-box thead .color-box').addClass('selected');
    $('.sizes-box tbody input').prop('checked', true);
  });

  $('.checkbox .cr').click(function(){
    checkCell(this);
  });

  setToUpdateCurrencyPriceField();
});

function removeRow(obj){
  $(obj).parentsUntil('tbody').remove();
};

function checkColumn(obj) {
  idx = $(obj).attr('data-idx');
  if ($(obj).find('.selected').length == 0) {
    $('.sizes-box tbody tr td:nth-child(' + idx + ')').find('input').prop('checked', false);
  } else {
    $('.sizes-box tbody tr td:nth-child(' + idx + ')').find('input').prop('checked', true);
  }
}

function checkCell(obj) {
  p = $(obj).find('input').prop('checked');
  $(obj).find('input').prop('checked', !p);
}

function toggleSelection(obj){
  if (!$(obj).hasClass('selectable')) {
    $(obj).toggleClass('selected');
  }
}
