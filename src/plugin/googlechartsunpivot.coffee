class Annotator.Plugin.EEAGoogleChartsUnpivotAnnotation extends Annotator.Plugin
    constructor: (element, options) ->
        @element = element
        @options = options

        $(window).unbind("EEAGoogleChartsUnpivotAnnotation.events.inputChanged")
        $(window).bind("EEAGoogleChartsUnpivotAnnotation.events.inputChanged", @changeTextArea)

    pluginInit: ->
        @annotator.editor.addField({
            label: 'dummyField',
            type: 'input',
            load: this.overrideEditor
        })
        @annotator.viewer.addField({
            load: this.overrideViewer
        })
        return

    overrideEditor: (annotation) ->
        $(@element).parent().find("textarea")
            .attr("placeholder", "")
            .attr("readonly", "readonly")
            .css("color", "transparent")
            .addClass("hiddenAnnotatorTextArea")

        annot = $(".hiddenAnnotatorTextArea").attr("value")
        obj = jQuery(this.element).parent().find("textarea").parent()

        $(@element).remove()
        $(".googlechartAnnotationEditorTable").html("")
        $(".googlechartAnnotationViewerTable").remove()
        $("<table>")
            .attr("style", "position:absolute; left:10px; top:-95px;")
            .addClass("googlechartAnnotationEditorTable")
            .appendTo(obj)
        $("<tr>")
            .addClass("googlechartAnnotationColumnType")
            .appendTo(".googlechartAnnotationEditorTable")
        $("<td>")
            .text("Column Type")
            .appendTo(".googlechartAnnotationColumnType")
        $("<td>")
            .html("<select>")
            .appendTo(".googlechartAnnotationColumnType")
        $("<option>")
            .attr("value", "base")
            .text("base")
            .appendTo(".googlechartAnnotationColumnType select")
        $("<option>")
            .attr("value", "pivot")
            .text("pivot")
            .appendTo(".googlechartAnnotationColumnType select")

        $("<tr>")
            .addClass("googlechartAnnotationColumnName")
            .appendTo(".googlechartAnnotationEditorTable")
        $("<td>")
            .text("Column Name")
            .appendTo(".googlechartAnnotationColumnName")
        $("<td>")
            .html("<input type='text' style='padding:3px;margin-top:5px; margin-bottom:5px;'>")
            .appendTo(".googlechartAnnotationColumnName")

        $("<tr>")
            .addClass("googlechartAnnotationValueType")
            .appendTo(".googlechartAnnotationEditorTable")
        $("<td>")
            .text("Value Type")
            .appendTo(".googlechartAnnotationValueType")
        $("<td>")
            .html("<select>")
            .appendTo(".googlechartAnnotationValueType")
        $("<option>")
            .attr("value", "string")
            .text("string")
            .appendTo(".googlechartAnnotationValueType select")
        $("<option>")
            .attr("value", "number")
            .text("number")
            .appendTo(".googlechartAnnotationValueType select")

        $(".googlechartAnnotationEditorTable select").bind(
            "change", () ->
                $(window).trigger("EEAGoogleChartsUnpivotAnnotation.events.inputChanged")
                return
        )

        $(".googlechartAnnotationEditorTable input").bind(
            "change", () ->
                $(window).trigger("EEAGoogleChartsUnpivotAnnotation.events.inputChanged")
                return
        )

        if annot != ""
            annot = JSON.parse(annot)
            $(".googlechartAnnotationColumnType select").attr("value", annot.colType)
            $(".googlechartAnnotationColumnName input").attr("value", annot.colName)
            $(".googlechartAnnotationValueType select").attr("value", annot.valType)

        $(window).trigger("EEAGoogleChartsUnpivotAnnotation.events.inputChanged")
        return

    overrideViewer: (annotation) ->
        if $(".googlechartAnnotationEditorTable").is(":visible")
            return

        obj = $(".annotator-widget.annotator-listing")
        annot = JSON.parse(obj.find("div:first").text())
        obj.find("div").remove()

        $("<table style='margin:10px'>")
            .addClass("googlechartAnnotationViewerTable")
            .appendTo(obj)
        $("<tr>")
            .addClass("googlechartAnnotationColumnType")
            .appendTo(".googlechartAnnotationViewerTable")
        $("<td>")
            .text("Column Type:")
            .appendTo(".googlechartAnnotationColumnType")
        $("<td style='font-weight:bold; padding-left:5px;'>")
            .text(annot.colType)
            .appendTo(".googlechartAnnotationColumnType")
        if annot.colType == 'base'
            return

        $("<tr>")
            .addClass("googlechartAnnotationColumnName")
            .appendTo(".googlechartAnnotationViewerTable")
        $("<td>")
            .text("Column Name:")
            .appendTo(".googlechartAnnotationColumnName")
        $("<td style='font-weight:bold; padding-left:5px;'>")
            .text(annot.colName)
            .appendTo(".googlechartAnnotationColumnName")

        $("<tr>")
            .addClass("googlechartAnnotationValueType")
            .appendTo(".googlechartAnnotationViewerTable")
        $("<td>")
            .text("Value Type:")
            .appendTo(".googlechartAnnotationValueType")
        $("<td style='font-weight:bold; padding-left:5px;'>")
            .text(annot.valType)
            .appendTo(".googlechartAnnotationValueType")
        return

    changeTextArea: ->
        colType = $(".googlechartAnnotationColumnType select option:selected").attr("value")
        colName = jQuery(".googlechartAnnotationColumnName input").attr("value")
        valType = jQuery(".googlechartAnnotationValueType select option:selected").attr("value")
        obj = {}
        obj.colType = colType
        obj.colName = colName
        obj.valType = valType
        $("li.annotator-item textarea").attr("value", JSON.stringify(obj))
        if colType == 'base'
            $(".googlechartAnnotationColumnName").hide()
            $(".googlechartAnnotationValueType").hide()
            return
        else
            $(".googlechartAnnotationColumnName").show()
            $(".googlechartAnnotationValueType").show()
            return

    getAnnotations: ->
        return $('.annotator-hl')
                    .addBack()
                    .map -> $(this).data("annotation")

