package com.unazed.LibraryManagement;

import com.unazed.LibraryManagement.model.User;

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
    private final User user;

    public UserAuthenticatedEvent(User user)
    {
      this.user = user;
    }

    public User getUser()
    {
      return user;
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