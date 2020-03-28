import 'package:app/form_fields/other_option.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

class DeliveryFormFields {
  static final deliveryFields = [
    'I have a car to drop off supplies to the drop off location',
    'I would like someone from the Medical Supply Drive team to pick-up from me',
    'I am fine with either option',
    OtherOption.value
  ];

  static final options = deliveryFields
      .map<FormBuilderFieldOption>((deliveryField) =>
          FormBuilderFieldOption(child: Text('$deliveryField'), value: '$deliveryField'))
      .toList();

}