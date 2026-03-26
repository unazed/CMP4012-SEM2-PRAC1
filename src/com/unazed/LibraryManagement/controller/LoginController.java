package com.unazed.LibraryManagement.controller;

import java.sql.SQLException;
import java.util.List;
import java.util.logging.Logger;

import com.unazed.LibraryManagement.EventBus;
import com.unazed.LibraryManagement.Events;
import com.unazed.LibraryManagement.LockableView;
import com.unazed.LibraryManagement.SqlApiResult;
import com.unazed.LibraryManagement.SqlInterface;
import com.unazed.LibraryManagement.View;
import com.unazed.LibraryManagement.ViewController;
import com.unazed.LibraryManagement.model.User;

import javafx.fxml.FXML;
import javafx.scene.control.Button;
import javafx.scene.control.PasswordField;
import javafx.scene.control.TextField;
import javafx.scene.control.Alert.AlertType;

@ViewController.ViewName(View.LOGIN)
public class LoginController extends ViewController
{
  @FXML private TextField tfLoginEmail;
  @FXML private PasswordField tfLoginPassword;
  @FXML private Button btnLogin;

  private static final Logger logger = Logger.getLogger(
    LoginController.class.getName());
  private final LockableView lockableView = new LockableView();

  @FXML
  public void initialize()
  {
    lockableView.lockableElements
      = List.of(tfLoginEmail, tfLoginPassword, btnLogin);
  }

  @FXML
  private void onLoginClick()
  {
    lockableView.lockView();

    String email = tfLoginEmail.getText();
    String password = tfLoginPassword.getText();
    EventBus eventBus = EventBus.get();

    if (email.isEmpty() || password.isEmpty())
    {
      eventBus.publish(
        new Events.StatusMessageEvent("Please fill in all fields."));
      lockableView.unlockView();
      return;
    }

    logger.info("Attempting login with email: " + email);
    try (SqlApiResult<User> result = SqlInterface.get().login(email, password))
    {
      if (!result.isSuccess())
      {
        logger.info("Failed to login with email: " + email);
        eventBus.publish(new Events.StatusMessageEvent(
          "Login failed: " + result.getErrorCode()));
        lockableView.unlockView();
        return;
      }
      logger.info("User logged in: " + email);
      eventBus.publish(new Events.UserAuthenticatedEvent(result.getData()));
    } catch (SQLException sqlExc)
    {
      eventBus.publish(
        new Events.AlertEvent(AlertType.ERROR, "db.connection.error"));
      lockableView.unlockView();
    }
  }
}