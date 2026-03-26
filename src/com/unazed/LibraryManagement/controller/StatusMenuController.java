package com.unazed.LibraryManagement.controller;

import com.unazed.LibraryManagement.EventBus;
import com.unazed.LibraryManagement.Events;
import com.unazed.LibraryManagement.View;
import com.unazed.LibraryManagement.ViewController;
import com.unazed.LibraryManagement.model.User;

import javafx.fxml.FXML;
import javafx.scene.control.Label;

@ViewController.ViewName(View.APP_MENU)
@ViewController.AllowedRoles({User.Role.Librarian, User.Role.Member})
public class StatusMenuController extends ViewController
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
