package com.unazed.LibraryManagement.controller;

import java.sql.SQLException;
import java.util.logging.Logger;

import com.unazed.LibraryManagement.EventBus;
import com.unazed.LibraryManagement.Events;
import com.unazed.LibraryManagement.SqlApiResult;
import com.unazed.LibraryManagement.SqlInterface;
import com.unazed.LibraryManagement.View;
import com.unazed.LibraryManagement.model.User;

import javafx.fxml.FXML;
import javafx.scene.control.Button;
import javafx.scene.control.PasswordField;
import javafx.scene.control.TextField;

public class LoginController
{
  @FXML private TextField tfLoginEmail;
  @FXML private PasswordField tfLoginPassword;
  @FXML private Button btnLogin;

  private static final Logger logger = Logger.getLogger(
    LoginController.class.getName());
  public static final View VIEW = View.LOGIN;

  @FXML
  public void initialize()
  {
  }

  @FXML
  private void onLoginClick()
  {
    String email = tfLoginEmail.getText();
    String password = tfLoginPassword.getText();

    if (email.isEmpty() || password.isEmpty())
    {
      return;
    }

    SqlInterface sqlInterface = SqlInterface.get();
    try (SqlApiResult<User> result = sqlInterface.login(email, password))
    {
      if (!result.isSuccess())
      {
        logger.info("Failed to login with email: " + email);
        return;
      }
      EventBus.get().publish(
        new Events.UserAuthenticatedEvent(result.getData()));
    } catch (SQLException sqlExc) { return; }
  }
}