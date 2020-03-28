import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

class OtherOption {
  static final value = 'Other...';

  static final isSelected = (List options) => options.contains(OtherOption.value);

  static final validator = (GlobalKey<FormBuilderState> _formKey, String field, String msg) => (val) => 
    _formKey.currentState.fields[field].currentState.value &&
    _formKey.currentState.fields[field].currentState.value.contains(OtherOption.value) && 
    (val == null || val.isEmpty) ? msg : null;

}
  