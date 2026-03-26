package com.unazed.LibraryManagement.controller;

import com.unazed.LibraryManagement.EventBus;
import com.unazed.LibraryManagement.Events;
import com.unazed.LibraryManagement.View;
import com.unazed.LibraryManagement.ViewController;

import javafx.fxml.FXML;
import javafx.scene.control.MenuItem;

@ViewController.ViewName(View.AUTH_MENU)
public class AuthMenuController extends ViewController
{
  @FXML private MenuItem miViewRegister;
  @FXML private MenuItem miViewLogin;
  @FXML private MenuItem miPreferencesConfigDb;
  @FXML private MenuItem miHelpAbout;

  @FXML
  private void onViewLogin()
  {
    EventBus.get().publish(new Events.ViewSwitchEvent(View.LOGIN));
  }

  @FXML
  private void onViewRegister()
  {
    EventBus.get().publish(new Events.ViewSwitchEvent(View.REGISTER));
  }

  @FXML
  private void onPreferencesConfigDb()
  {
    EventBus.get().publish(new Events.ViewSwitchEvent(View.CONFIG_DB));
  }

  @FXML
  private void onHelpAbout()
  {
    EventBus.get().publish(new Events.ViewSwitchEvent(View.ABOUT));
  }
}