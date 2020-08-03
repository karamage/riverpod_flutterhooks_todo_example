import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:state_notifier/state_notifier.dart';

import 'todo.dart';

// Some keys used for testing
final addTodoKey = UniqueKey();
final activeFilterKey = UniqueKey();
final completedFilterKey = UniqueKey();
final allFilterKey = UniqueKey();

// Creates a [TodoList] and initialise it with pre-defined values.

// We are using [StateNotifierProvider] here as a List<Todo> is a complex object
// with advanced business logic like how to edit a todo.
final todoListProvider = StateNotifierProvider((ref) {
  return TodoList([
    Todo(id: 'todo-0', description: 'hi'),
    Todo(id: 'todo-1', description: 'hello'),
    Todo(id: 'todo-2', description: 'bonjour'),
  ]);
});

// The different ways to filter the list of todos
enum TodoListFilter {
  all,
  active,
  completed,
}

// The current active filter
//
// We use [StateProvider] here as there is no fancy loginc behind manipulating
// the value since it's just enum.
final todoListFilter = StateProvider((_) => TodoListFilter.all);

// The number of uncompleted todos
//
// By using [Computed], this value is cached, making it performant.
// Even multiple widgets try to read the number of uncompleted todos,
// the value will be computed only once (until the todo-list changes).
//
// This will also optimise unneeded rebuilds if the todo-list changes, but the
// number of uncompleted todos does'nt(such as when editing a todo).
final uncompletedTodosCount = Computed((read) {
  return read(todoListProvider.state).where((todo) => !todo.completed).length;
});

// The List of todos after applying of [todoListFilter]
//
// This too uses [Computed], to avoid recomputing the filtered unless either
// the filter of or the todo-list updates
final filteredTodos = Computed((read) {
  final filter = read(todoListFilter);
  final todos = read(todoListProvider.state);

  switch (filter.state) {
    case TodoListFilter.completed:
      return todos.where((todo) => todo.completed).toList();
    case TodoListFilter.active:
      return todos.where((todo) => !todo.completed).toList();
    case TodoListFilter.all:
    default:
      return todos;
  }
});

void main() {
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Home(),
    );
  }
}

class Home extends HookWidget {
  const Home({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final todos = useProvider(filteredTodos);
    final newTodoController = useTextEditingController();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          children: <Widget>[
            //TODO
          ],
        ),
      ),
    );
  }
}

class Title extends StatelessWidget {
  const Title({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Text(
      'todos',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Color.fromARGB(38, 47, 47, 247),
        fontSize: 100,
        fontWeight: FontWeight.w100,
        fontFamily: 'Helvetica Neue',
      ),
    );
  }
}

class TodoItem extends HookWidget {
  const TodoItem(this.todo, {Key key}) : super(key: key);

  final Todo todo;

  @override
  Widget build(BuildContext context) {
    final itemFocusNode = useFocusNode();
    useListenable(itemFocusNode);
    final isFocused = itemFocusNode.hasFocus;

    final textEditingController = useTextEditingController();
    final textFieldFocusNode = useFocusNode();

    return Material(
      color: Colors.white,
      elevation: 6,
      child: Focus(
        focusNode: itemFocusNode,
        onFocusChange: (focused) {
          if (focused) {
            textEditingController.text = todo.description;
          } else {
            todoListProvider
              .read(context)
              .edit(id: todo.id, description: textEditingController.text);
          }
        },
        child: ListTile(
          onTap: () {
            itemFocusNode.requestFocus();
            textFieldFocusNode.requestFocus();
          },
          leading: Checkbox(
            value: todo.completed,
            onChanged: (value) =>
              todoListProvider.read(context).toggle(todo.id),
          ),
          title: isFocused
            ? TextField(
              autofocus: true,
              focusNode: textFieldFocusNode,
              controller: textEditingController,
            )
            : Text(todo.description),
        ),
      ),
    );
  }
}