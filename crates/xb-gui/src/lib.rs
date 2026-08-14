use thiserror::Error;

#[derive(Debug, Error, PartialEq, Eq)]
pub enum GuiError {
    #[error("point is outside framebuffer bounds")]
    OutOfBounds,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Color(pub u32);

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Point {
    pub x: i32,
    pub y: i32,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Size {
    pub width: usize,
    pub height: usize,
}

pub trait GdiSurface {
    fn clear(&mut self, color: Color);
    fn set_pixel(&mut self, point: Point, color: Color) -> Result<(), GuiError>;
    fn draw_line(&mut self, start: Point, end: Point, color: Color) -> Result<(), GuiError>;
    fn fill_rect(&mut self, origin: Point, size: Size, color: Color) -> Result<(), GuiError>;
    fn move_to(&mut self, point: Point);
    fn line_to(&mut self, point: Point, color: Color) -> Result<(), GuiError>;
    fn set_text_color(&mut self, color: Color);
    fn set_background_color(&mut self, color: Color);
    fn text_out(&mut self, point: Point, text: &str) -> Result<(), GuiError>;
    fn bit_blt(
        &mut self,
        dst: Point,
        src: &Framebuffer,
        src_origin: Point,
        size: Size,
    ) -> Result<(), GuiError>;
    fn width(&self) -> usize;
    fn height(&self) -> usize;
    fn pixels(&self) -> &[u32];
    fn pixels_mut(&mut self) -> &mut [u32];
    fn current_pos(&self) -> Point;
    fn text_color(&self) -> Color;
    fn background_color(&self) -> Color;
}

#[derive(Debug, Clone)]
pub struct Framebuffer {
    size: Size,
    pixels: Vec<u32>,
    current_pos: Point,
    text_color: Color,
    background_color: Color,
}

impl Framebuffer {
    pub fn new(size: Size, background: Color) -> Self {
        let len = size.width.saturating_mul(size.height);
        Self {
            size,
            pixels: vec![background.0; len],
            current_pos: Point { x: 0, y: 0 },
            text_color: Color(0x00ff_ffff),
            background_color: background,
        }
    }

    fn index(&self, point: Point) -> Result<usize, GuiError> {
        if point.x < 0 || point.y < 0 {
            return Err(GuiError::OutOfBounds);
        }
        let x = usize::try_from(point.x).map_err(|_| GuiError::OutOfBounds)?;
        let y = usize::try_from(point.y).map_err(|_| GuiError::OutOfBounds)?;
        if x >= self.size.width || y >= self.size.height {
            return Err(GuiError::OutOfBounds);
        }
        Ok((y * self.size.width) + x)
    }
}

impl GdiSurface for Framebuffer {
    fn clear(&mut self, color: Color) {
        self.pixels.fill(color.0);
    }

    fn set_pixel(&mut self, point: Point, color: Color) -> Result<(), GuiError> {
        let index = self.index(point)?;
        self.pixels[index] = color.0;
        Ok(())
    }

    fn draw_line(&mut self, start: Point, end: Point, color: Color) -> Result<(), GuiError> {
        let mut x = start.x;
        let mut y = start.y;
        let dx = (end.x - start.x).abs();
        let sx = if start.x < end.x { 1 } else { -1 };
        let dy = -(end.y - start.y).abs();
        let sy = if start.y < end.y { 1 } else { -1 };
        let mut err = dx + dy;
        loop {
            self.set_pixel(Point { x, y }, color)?;
            if x == end.x && y == end.y {
                break;
            }
            let err2 = err * 2;
            if err2 >= dy {
                err += dy;
                x += sx;
            }
            if err2 <= dx {
                err += dx;
                y += sy;
            }
        }
        Ok(())
    }

    fn fill_rect(&mut self, origin: Point, size: Size, color: Color) -> Result<(), GuiError> {
        for y in 0..size.height {
            for x in 0..size.width {
                let px = origin.x + i32::try_from(x).map_err(|_| GuiError::OutOfBounds)?;
                let py = origin.y + i32::try_from(y).map_err(|_| GuiError::OutOfBounds)?;
                self.set_pixel(Point { x: px, y: py }, color)?;
            }
        }
        Ok(())
    }

    fn move_to(&mut self, point: Point) {
        self.current_pos = point;
    }

    fn line_to(&mut self, point: Point, color: Color) -> Result<(), GuiError> {
        let start = self.current_pos;
        self.draw_line(start, point, color)?;
        self.current_pos = point;
        Ok(())
    }

    fn set_text_color(&mut self, color: Color) {
        self.text_color = color;
    }

    fn set_background_color(&mut self, color: Color) {
        self.background_color = color;
    }

    fn text_out(&mut self, point: Point, text: &str) -> Result<(), GuiError> {
        let width = text.chars().count().max(1);
        self.fill_rect(point, Size { width, height: 1 }, self.text_color)
    }

    fn bit_blt(
        &mut self,
        dst: Point,
        src: &Framebuffer,
        src_origin: Point,
        size: Size,
    ) -> Result<(), GuiError> {
        for y in 0..size.height {
            for x in 0..size.width {
                let sx = src_origin.x + i32::try_from(x).map_err(|_| GuiError::OutOfBounds)?;
                let sy = src_origin.y + i32::try_from(y).map_err(|_| GuiError::OutOfBounds)?;
                let dx = dst.x + i32::try_from(x).map_err(|_| GuiError::OutOfBounds)?;
                let dy = dst.y + i32::try_from(y).map_err(|_| GuiError::OutOfBounds)?;
                let color = Color(src.pixels[src.index(Point { x: sx, y: sy })?]);
                self.set_pixel(Point { x: dx, y: dy }, color)?;
            }
        }
        Ok(())
    }

    fn width(&self) -> usize {
        self.size.width
    }
    fn height(&self) -> usize {
        self.size.height
    }
    fn pixels(&self) -> &[u32] {
        &self.pixels
    }
    fn pixels_mut(&mut self) -> &mut [u32] {
        &mut self.pixels
    }
    fn current_pos(&self) -> Point {
        self.current_pos
    }
    fn text_color(&self) -> Color {
        self.text_color
    }
    fn background_color(&self) -> Color {
        self.background_color
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn draws_diagonal_line_into_framebuffer() {
        let mut fb = Framebuffer::new(
            Size {
                width: 3,
                height: 3,
            },
            Color(0),
        );
        fb.draw_line(Point { x: 0, y: 0 }, Point { x: 2, y: 2 }, Color(1))
            .unwrap();
        assert_eq!(fb.pixels(), &[1, 0, 0, 0, 1, 0, 0, 0, 1]);
    }
}
