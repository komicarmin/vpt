// #package js/main

// #include ../AbstractDialog.js
// #include ../../TransferFunctionWidget.js

// #include ../../../uispecs/renderers/MYRendererDialog.json

class MYRendererDialog extends AbstractDialog {

constructor(renderer, options) {
    super(UISPECS.MYRendererDialog, options);

    this._renderer = renderer;

    this._handleChange = this._handleChange.bind(this);
    this._handleTFChange = this._handleTFChange.bind(this);

    this._binds.steps.addEventListener('input', this._handleChange);
    this._binds.opacity.addEventListener('input', this._handleChange);
    this._binds.direction.addEventListener('input', this._handleChange);
    this._binds.intensity.addEventListener('input', this._handleChange);
    this._binds.lcolor.addEventListener('input', this._handleChange);
    this._binds.ltype.addEventListener('input', this._handleChange);
    this._binds.reflection.addEventListener('input', this._handleChange);

    this._tfwidget = new TransferFunctionWidget();
    this._binds.tfcontainer.add(this._tfwidget);
    this._tfwidget.addEventListener('change', this._handleTFChange);

    this._handleChange()
}

destroy() {
    this._tfwidget.destroy();
    super.destroy();
}

_handleChange() {
    this._renderer._stepSize = 1 / this._binds.steps.getValue();
    this._renderer._alphaCorrection = this._binds.opacity.getValue();

    this._renderer._ltype = this._binds.ltype.getValue();
    this._renderer._reflection = this._binds.reflection.getValue();
    const direction = this._binds.direction.getValue();
    this._renderer._light[0] = direction.x;
    this._renderer._light[1] = direction.y;
    this._renderer._light[2] = direction.z;
    this._renderer._intensity = this._binds.intensity.getValue();
    
    const color = CommonUtils.hex2rgb(this._binds.lcolor.getValue());
    this._renderer._lcolor[0] = color.r;
    this._renderer._lcolor[1] = color.g;
    this._renderer._lcolor[2] = color.b;

    this._renderer.reset();
}

_handleTFChange() {
    this._renderer.setTransferFunction(this._tfwidget.getTransferFunction());
    this._renderer.reset();
}

}
