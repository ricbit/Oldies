function onOpen() {
  var ui = DocumentApp.getUi();
  ui.createMenu('Custom Menu')
    .addItem('Code Style', 'codeStyle')
    .addToUi();
}

function codeStyle() {
 var selection = DocumentApp.getActiveDocument().getSelection();
 if (selection) { 
   var rangeElements = selection.getRangeElements();
   for (var i = 0; i < rangeElements.length; i++) {
     var element = rangeElements[i].getElement();
     if (element.getType() == DocumentApp.ElementType.TEXT) {
       if (rangeElements[i].isPartial()) {
         var start = rangeElements[i].getStartOffset();
         var end = rangeElements[i].getEndOffsetInclusive();
         element.setFontSize(start, end, 11);
         element.setFontFamily(start, end, "Courier New");
         element.setBackgroundColor(start, end, "#d9d9d9");
       }
     }
   }
 }
}
