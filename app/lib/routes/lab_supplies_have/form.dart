import 'package:app/form_fields/medical_equipment.dart';
import 'package:app/form_fields/states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

class HaveLabSuppliesForm extends StatefulWidget {
  @override
  HaveLabSuppliesFormState createState() {
    return HaveLabSuppliesFormState();
  }
}

class HaveLabSuppliesFormState extends State<HaveLabSuppliesForm> {

  final GlobalKey<FormBuilderState> _fbKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {

    // Build a Form widget using the _formKey created above.
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          FormBuilder(
            // context,
            key: _fbKey,
            autovalidate: true,
            initialValue: {},
            readOnly: false,
            child: Column(
              children: <Widget>[
                FormBuilderTextField(
                  attribute: "email",
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email address',
                    hintText: 'Your email'
                  ),
                  validators: [
                    FormBuilderValidators.required(),
                    FormBuilderValidators.email(),
                  ]
                ),
                FormBuilderTextField(
                  attribute: "name",
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    hintText: 'Your answer'
                  ),
                  validators: [
                    FormBuilderValidators.required(),
                    FormBuilderValidators.minLength(3),
                  ]
                ),
                FormBuilderTextField(
                  attribute: "city",
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    labelText: 'City',
                    hintText: 'Your answer'
                  ),
                  validators: [
                    FormBuilderValidators.required(),
                    FormBuilderValidators.minLength(2),
                  ]
                ),
                FormBuilderCheckboxList(
                  attribute: "state",
                  options: StateFormFields.options,
                  validators: [
                    FormBuilderValidators.required(),
                  ],
                ),
                FormBuilderTextField(
                  attribute: "phone",
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number (to contact about pickup/drop-off information)',
                    hintText: 'Your answer'
                  ),
                  validators: [
                    FormBuilderValidators.required(),
                    FormBuilderValidators.pattern(r'(^(?:[+0]9)?[0-9]{10,12}$)')
                  ]
                ),
                FormBuilderCheckboxList(
                  attribute: "medical_equipment",
                  options: MedicalEquipmentFormFields.options,
                  validators: [
                    FormBuilderValidators.required(),
                  ],
                ),
              ]
            )
          ),
          Row(
            children: <Widget>[
              Expanded(
                child: MaterialButton(
                  color: Theme.of(context).accentColor,
                  child: Text(
                    "Submit",
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () {
                    if (_fbKey.currentState.saveAndValidate()) {
                      print(_fbKey.currentState.value);
                    } else {
                      print(_fbKey.currentState.value);
                      print("validation failed");
                    }
                  },
                ),
              ),
              // SizedBox(
              //   width: 20,
              // ),
              // Expanded(
              //   child: MaterialButton(
              //     color: Theme.of(context).accentColor,
              //     child: Text(
              //       "Reset",
              //       style: TextStyle(color: Colors.white),
              //     ),
              //     onPressed: () {
              //       _fbKey.currentState.reset();
              //     },
              //   ),
              // ),
            ],
          ),
        ]
      )
    );
  }
}