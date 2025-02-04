#pragma once

#include <Processors/Formats/Impl/PrettyBlockOutputFormat.h>
#include <optional>
#include <unordered_map>


namespace DB
{

/** Prints the result in the form of beautiful tables, but with fewer delimiter lines.
  */
class PrettyCompactBlockOutputFormat : public PrettyBlockOutputFormat
{
public:
    PrettyCompactBlockOutputFormat(WriteBuffer & out_, const Block & header, const FormatSettings & format_settings_, bool mono_block_, bool color);
    String getName() const override { return "PrettyCompactBlockOutputFormat"; }

private:
    void writeHeader(const Block & block, const Widths & max_widths, const Widths & name_widths, const Strings & names, bool write_footer);
    void writeBottom(const Widths & max_widths);
    void writeRow(
        size_t row_num,
        size_t displayed_row,
        const Block & header,
        const Chunk & chunk,
        const WidthsPerColumn & widths,
        const Widths & max_widths);
    void writeVerticalCut(const Chunk & chunk, const Widths & max_widths);

    void writeChunk(const Chunk & chunk, PortKind port_kind) override;
};

}
