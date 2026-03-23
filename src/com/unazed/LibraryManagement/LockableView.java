package com.unazed.LibraryManagement;

import java.util.List;

import javafx.scene.Node;

public class LockableView
{
  private boolean isLocked = false;
  public List<Node> lockableElements;

  public void lockView()
  {
    if (isLocked)
      return;
    lockableElements.forEach(node -> node.setDisable(true));
    isLocked = true;
  }

  public void unlockView()
  {
    if (!isLocked)
      return;
    lockableElements.forEach(node -> node.setDisable(false));
    isLocked = false;
  }
}
