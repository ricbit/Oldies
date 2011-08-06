// Spectrum editor
// Written by Ricardo Bittencourt, 2009

package com.ricbit.client;

import gwt.canvas.client.Canvas;

import com.google.gwt.core.client.EntryPoint;
import com.google.gwt.user.client.ui.Button;
import com.google.gwt.user.client.ui.FlexTable;
import com.google.gwt.user.client.ui.HTML;
import com.google.gwt.user.client.ui.RootPanel;

public class Spectrum implements EntryPoint {


  public void onModuleLoad() {
    final Button clearButton = new Button("Clear");
    final HTML colorPanel = new HTML();
    final Canvas canvas = new Canvas(
        SpectrumConstants.CANVAS_WIDTH, SpectrumConstants.CANVAS_HEIGHT);
    colorPanel.setSize("100px", "30px");

    SpectrumView view = new SpectrumView(canvas, colorPanel);
    SpectrumLogic logic = new SpectrumLogic(view);
    SpectrumMouseListener mouseListener = new SpectrumMouseListener(logic);
    SpectrumClickListener clickListener = new SpectrumClickListener(logic);
    logic.clear();

    FlexTable panel = new FlexTable();
    panel.setWidth("450px");
    panel.setWidget(0, 0, canvas);
    panel.setWidget(1, 0, clearButton);
    panel.setWidget(1, 1, colorPanel);
    panel.getFlexCellFormatter().setColSpan(0, 0, 2);
        
    RootPanel.get().add(panel);

    canvas.addMouseListener(mouseListener);
    clearButton.addClickListener(clickListener);
  }
}
