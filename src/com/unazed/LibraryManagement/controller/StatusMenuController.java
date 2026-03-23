package com.unazed.LibraryManagement.controller;

import com.unazed.LibraryManagement.EventBus;
import com.unazed.LibraryManagement.Events;

import javafx.fxml.FXML;
import javafx.scene.control.Label;

public class StatusMenuController
{
  @FXML private Label labelStatus;

  @FXML
  public void initialize()
  {
    EventBus.get().subscribe(Events.StatusMessageEvent.class, event -> {
      setStatus(event.getMessage());
    });
  }

  public void setStatus(String message)
  {
    labelStatus.setText(message);
  }
}
