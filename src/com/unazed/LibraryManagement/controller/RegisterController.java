package com.unazed.LibraryManagement.controller;

import java.sql.SQLException;
import java.util.List;

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

@ViewController.ViewName(View.REGISTER)
public class RegisterController extends ViewController
{
  @FXML private TextField tfRegisterEmail;
  @FXML private TextField tfRegisterUsername;
  @FXML private PasswordField tfRegisterPassword;
  @FXML private PasswordField tfRegisterConfirmPassword;
  @FXML private Button btnRegister;

  private final LockableView lockableView = new LockableView();

  @FXML
  public void initialize()
  {
    lockableView.lockableElements = List.of(
      tfRegisterEmail, tfRegisterUsername, tfRegisterPassword,
      tfRegisterConfirmPassword, btnRegister);
  }

  @FXML
  private void onRegisterClick()
  {
    lockableView.lockView();
    String email = tfRegisterEmail.getText();
    String username = tfRegisterUsername.getText();
    String password = tfRegisterPassword.getText();
    String confirmPassword = tfRegisterConfirmPassword.getText();
    EventBus eventBus = EventBus.get();

    if (email.isEmpty() || username.isEmpty() 
        || password.isEmpty() || confirmPassword.isEmpty())
    {
      eventBus.publish(
        new Events.StatusMessageEvent("Please fill in all fields."));
      lockableView.unlockView();
      return;
    }

    if (!email.contains("@"))
    {
      eventBus.publish(
        new Events.StatusMessageEvent("Please enter a valid email address."));
      lockableView.unlockView();
      return;
    }

    if (username.length() < 3)
    {
      eventBus.publish(
        new Events.StatusMessageEvent(
          "Username must be at least 3 characters."));
      lockableView.unlockView();
      return;
    }

    if (!password.equals(confirmPassword))
    {
      eventBus.publish(
        new Events.StatusMessageEvent("Passwords do not match."));
      lockableView.unlockView();
      return;
    }

    try (SqlApiResult<User> result
      = SqlInterface.get().register(email, username, password))
    {
      if (!result.isSuccess())
      {
        eventBus.publish(new Events.StatusMessageEvent(
          "Registration failed: " + result.getErrorCode()));
        lockableView.unlockView();
        return;
      }
      eventBus.publish(new Events.UserAuthenticatedEvent(result.getData()));
    } catch (SQLException exc) {
      eventBus.publish(
        new Events.AlertEvent(AlertType.ERROR, "db.connection.error"));
      lockableView.unlockView();
    }

  }
}