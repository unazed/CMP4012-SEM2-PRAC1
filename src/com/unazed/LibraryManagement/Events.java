package com.unazed.LibraryManagement;

import java.util.logging.Logger;

import com.unazed.LibraryManagement.model.gen.Users;

import javafx.scene.control.Alert.AlertType;

public class Events
{
  public static class ViewSwitchEvent
  {
    private final View view;

    public ViewSwitchEvent(View view)
    {
      this.view = view;
    }

    public View getView()
    {
      return view;
    }
  }

  public static class UserAuthenticatedEvent
  {
    private static final Logger logger = Logger.getLogger(
      UserAuthenticatedEvent.class.getName());

    private final Users user;
    private final String userToken;

    public UserAuthenticatedEvent(Users user, String userToken)
    {
      this.user = user;
      logger.info("user authenticated: " + user.username() + " (ID: " + user.user_id() + ")");
      logger.info("role: " + user.user_role());
      this.userToken = userToken;
    }

    public Users getUser()
    {
      return user;
    }

    public String getUserToken()
    {
      return userToken;
    }
  }

  public static class StatusMessageEvent
  {
    private final String message;

    public StatusMessageEvent(String message)
    {
      this.message = message;
    }

    public String getMessage()
    {
      return message;
    }
  }

  public static class AlertEvent
  {
    private final AlertType type;
    private final String title;
    private final String header;
    private final String content;

    public AlertEvent(AlertType type, String group)
    {
      this.type = type;
      this.title = Messages.get(group + ".title");
      this.header = Messages.get(group + ".header");
      this.content = Messages.get(group + ".content");
    }

    public String getTitle()
    {
      return title;
    }

    public String getHeader()
    {
      return header;
    }

    public String getContent()
    {
      return content;
    }

    public AlertType getType()
    {
      return type;
    }
  }

  public static class UserSignoutEvent
  {
    public UserSignoutEvent() {}
  }
}