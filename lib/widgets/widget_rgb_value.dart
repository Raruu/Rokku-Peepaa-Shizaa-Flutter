import 'package:flutter/material.dart';
import 'package:flutter_rps/models/rps_model.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class WidgetrgbValue extends StatelessWidget {
  const WidgetrgbValue({
    super.key,
    required this.context,
    required this.setState,
    required this.rpsModel,
    required this.sliderTitle,
    required this.rgbSuggestions,
    required this.enabled,
    required this.modifiedRgb,
    required this.onEditingComplete,
  });

  final BuildContext context;
  final StateSetter setState;
  final RpsModel rpsModel;
  final String sliderTitle;
  final List<List<double>> rgbSuggestions;
  final bool enabled;
  final List<double> modifiedRgb;
  final void Function(bool enabled, List<double> modifiedRgb) onEditingComplete;

  @override
  Widget build(BuildContext context) {
    const rgb = ['R', 'G', 'B'];
    final List<TextEditingController> controller = [
      TextEditingController(),
      TextEditingController(),
      TextEditingController(),
    ];
    for (var i = 0; i < controller.length; i++) {
      controller[i].text = modifiedRgb[i].toString();
    }

    return Column(
      children: [
        Row(
          children: [
            Text(sliderTitle,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const Spacer(),
            Switch(
              value: enabled,
              onChanged: (value) {
                onEditingComplete(value, modifiedRgb);
                setState(() {});
              },
            )
          ],
        ),
        Visibility(
          visible: enabled,
          child: Row(
            children: List.generate(
              rgb.length,
              (index) => Flexible(
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: TypeAheadField(
                    controller: controller[index],
                    builder: (context, controller, focusNode) {
                      return TextField(
                        onChanged: (value) {
                          modifiedRgb[index] = double.tryParse(value)!;
                          onEditingComplete(enabled, modifiedRgb);
                        },
                        keyboardType: TextInputType.number,
                        controller: controller,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          labelText: rgb[index],
                        ),
                      );
                    },
                    itemBuilder: (context, value) =>
                        ListTile(title: Text(value.toString())),
                    suggestionsCallback: (search) => List.generate(
                        rgbSuggestions[index].length,
                        (_) => rgbSuggestions[_][index]),
                    onSelected: (value) {
                      controller[index].text = value.toString();
                      modifiedRgb[index] = value;
                      onEditingComplete(enabled, modifiedRgb);
                    },
                  ),
                ),
              ),
            ),
          ),
        )
      ],
    );
  }
}
