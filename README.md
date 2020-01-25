# Delphi-Philips-Hue
Delphi Philips Hue Bridge component, quick connecting to Philips Hue bridge, switching/editing/adding/removing lights, groups, scenes and more!

THueBridge is a Delphi VCL component for Delphi 10+. I haven't tested it on Delphi versions below 10.1, but it should work fine from D2010. THueBridge is a simple non-visual component for communicating (zigbee protocol) with a Philips Hue Lighting system. Communicating with the bridge relies on Indy VCL and a custom JSON Parser (which is included).

This non-visual component is for communicating with Philips Hue Lights over zigbee protocol. You will need a Philips Hue Bridge, and have local access to the bridge. The component allows pairing with the bridge, and control almost everything.

You can switch lights, scenes, add and modify scenes and schedules, and much more.

Take a look at the demo for the functions, the download contains the THueBridge component and a custom JSON parser class - that is used in multiple projects. THueBridge uses this JSON Parser class, but you might want to rewrite the component to use Delphi's own JSON parser.

If you use it in your project, please just like our facebook page and credits would be nice :)
Please visit our website: https://erdesigns.eu and facebook page: https://fb.me/erdesigns.eu
