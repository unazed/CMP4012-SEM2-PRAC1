package com.unazed.LibraryManagement;

import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.function.Consumer;

import javafx.application.Platform;

public class EventBus {
  private static final EventBus INSTANCE = new EventBus();
  private final Map<Class<?>, List<Consumer<Object>>> listeners
    = new ConcurrentHashMap<>();

  public static EventBus get()
  {
    return INSTANCE;
  }

  @SuppressWarnings("unchecked")
  public <T> void subscribe(Class<T> event, Consumer<T> listener)
  {
    listeners.computeIfAbsent(event, k -> new CopyOnWriteArrayList<>())
             .add(e -> listener.accept((T) e));
  }

  public void publish(Object event)
  {
    List<Consumer<Object>> subscribers = listeners.getOrDefault(
      event.getClass(), List.of());
    if (Platform.isFxApplicationThread()) 
      subscribers.forEach(l -> l.accept(event));
    else
      Platform.runLater(() -> subscribers.forEach(l -> l.accept(event)));
  }
}