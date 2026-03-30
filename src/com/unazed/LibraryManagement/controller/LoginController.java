package com.unazed.LibraryManagement.controller;

import java.sql.SQLException;
import java.util.List;
import java.util.logging.Logger;
import java.util.prefs.Preferences;

import com.unazed.LibraryManagement.DatabaseFunctions;
import com.unazed.LibraryManagement.EventBus;
import com.unazed.LibraryManagement.Events;
import com.unazed.LibraryManagement.LockableView;
import com.unazed.LibraryManagement.View;
import com.unazed.LibraryManagement.ViewController;
import com.unazed.LibraryManagement.model.gen.ResultType;
import com.unazed.LibraryManagement.model.gen.Users;

import javafx.fxml.FXML;
import javafx.scene.control.Button;
import javafx.scene.control.CheckBox;
import javafx.scene.control.PasswordField;
import javafx.scene.control.TextField;
import javafx.scene.control.Alert.AlertType;

@ViewController.ViewName(View.LOGIN)
public class LoginController extends ViewController
{
  @FXML private TextField tfLoginEmail;
  @FXML private PasswordField tfLoginPassword;
  @FXML private Button btnLogin;
  @FXML private CheckBox cbRememberLogin;

  private static final Logger logger = Logger.getLogger(
    LoginController.class.getName());
  private final LockableView lockableView = new LockableView();
  private final EventBus eventBus = EventBus.get();

  @FXML
  public void initialize()
  {
    lockableView.lockableElements
      = List.of(tfLoginEmail, tfLoginPassword, btnLogin);
  }

  @Override
  public boolean postInitialize()
  {
    String storedToken = Preferences.userNodeForPackage(LoginController.class)
      .get("storedToken", null);
    if (storedToken != null)
      return !tryLoginWithToken(storedToken);
    return true;
  }

  private boolean tryLoginWithToken(String token)
  {
    logger.info("Attempting login with stored token");
    try
    {
      ResultType result = DatabaseFunctions.getTokenInformation(token);
      if (!result.success())
      {
        logger.info("Failed to login with stored token");
        eventBus.publish(new Events.StatusMessageEvent(
          "Token login failed: " + result.errorCode()));
        return false;
      }
      Users user = result.getDataAs(Users.class);
      logger.info("User logged in with token: " + user.email());
      eventBus.publish(new Events.UserAuthenticatedEvent(user, token));
      eventBus.publish(
        new Events.StatusMessageEvent("Logged in with stored token"));
      return true;
    } catch (SQLException sqlExc)
    {
      eventBus.publish(
        new Events.AlertEvent(AlertType.ERROR, "db.connection.error"));
      return false;
    }
  }

  @FXML
  private void onLoginClick()
  {
    lockableView.lockView();

    String email = tfLoginEmail.getText();
    String password = tfLoginPassword.getText();

    if (email.isEmpty() || password.isEmpty())
    {
      eventBus.publish(
        new Events.StatusMessageEvent("Please fill in all fields."));
      lockableView.unlockView();
      return;
    }

    logger.info("Attempting login with email: " + email);
    try
    {
      ResultType result = DatabaseFunctions.loginUser(email, password);
      if (!result.success())
      {
        logger.info("Failed to login with email: " + email);
        eventBus.publish(new Events.StatusMessageEvent(
          "Login failed: " + result.errorCode()));
        lockableView.unlockView();
        return;
      }
      logger.info("User logged in: " + email);
      String token = result.getDataField("token").getAsString();
      Users user = result.getDataAs(Users.class);
      if (cbRememberLogin.isSelected())
      {
        Preferences.userNodeForPackage(LoginController.class)
          .put("storedToken", token);
        logger.info("Remembering token for email: " + email);
      } else
      {
        Preferences.userNodeForPackage(LoginController.class)
          .remove("storedToken");
        logger.info("Clearing stored token for email: " + email);
      }
      eventBus.publish(
        new Events.UserAuthenticatedEvent(user, token));
    } catch (SQLException sqlExc)
    {
      eventBus.publish(
        new Events.AlertEvent(AlertType.ERROR, "db.connection.error"));
      lockableView.unlockView();
    }
  }
}