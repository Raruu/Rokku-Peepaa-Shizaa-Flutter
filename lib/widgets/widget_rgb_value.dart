import 'package:flutter/material.dart';
import 'package:flutter_rps/models/rps_model.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class WidgetrgbValue extends StatefulWidget {
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
  State<WidgetrgbValue> createState() => _WidgetrgbValueState();
}

class _WidgetrgbValueState extends State<WidgetrgbValue> {
  late final List<TextEditingController> controller;

  @override
  void initState() {
    controller = [
      TextEditingController(),
      TextEditingController(),
      TextEditingController(),
    ];
    for (var i = 0; i < controller.length; i++) {
      controller[i].text = widget.modifiedRgb[i].toString();
    }
    super.initState();
  }

  @override
  void dispose() {
    for (var item in controller) {
      item.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const rgb = ['R', 'G', 'B'];
    return Column(
      children: [
        Row(
          children: [
            Text(widget.sliderTitle,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const Spacer(),
            Switch(
              value: widget.enabled,
              onChanged: (value) {
                widget.onEditingComplete(value, widget.modifiedRgb);
                widget.setState(() {});
              },
            )
          ],
        ),
        Visibility(
          visible: widget.enabled,
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
                          widget.modifiedRgb[index] = double.tryParse(value)!;
                          widget.onEditingComplete(
                              widget.enabled, widget.modifiedRgb);
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
                        widget.rgbSuggestions[index].length,
                        (x) => widget.rgbSuggestions[x][index]),
                    onSelected: (value) {
                      controller[index].text = value.toString();
                      widget.modifiedRgb[index] = value;
                      widget.onEditingComplete(
                          widget.enabled, widget.modifiedRgb);
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
