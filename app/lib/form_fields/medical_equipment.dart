import 'package:app/form_fields/other_option.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

class MedicalEquipmentFormFields {
  static final equipment = [
    'Surgical masks',
    'N95 masks',
    'Face shields',
    'Bandanas (as recommended by the CDC)',
    'Non-latex gloves',
    'Medical/Surgical gowns',
    'Plastic rain ponchos',
    'Bleach/bleach wipes',
    'Hand sanitizer',
    OtherOption.value
  ];

  static final options = equipment
      .map<FormBuilderFieldOption>((equip) =>
          FormBuilderFieldOption(child: Text('$equip'), value: '$equip'))
      .toList();
}
