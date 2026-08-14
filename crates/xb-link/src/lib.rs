use std::path::{Path, PathBuf};
use std::process::Command;
use thiserror::Error;

#[derive(Debug, Error)]
pub enum LinkError {
    #[error("no object files were provided")]
    EmptyObjects,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct LinkRequest {
    objects: Vec<PathBuf>,
    output: PathBuf,
}

impl LinkRequest {
    pub fn new(objects: Vec<PathBuf>, output: PathBuf) -> Result<Self, LinkError> {
        if objects.is_empty() {
            return Err(LinkError::EmptyObjects);
        }
        Ok(Self { objects, output })
    }

    pub fn objects(&self) -> &[PathBuf] {
        &self.objects
    }

    pub fn output(&self) -> &Path {
        &self.output
    }
}

pub fn linker_command(request: &LinkRequest) -> Command {
    platform::linker_command(request)
}

#[cfg(not(windows))]
mod platform {
    use super::LinkRequest;
    use std::process::Command;

    pub fn linker_command(request: &LinkRequest) -> Command {
        let mut cmd = Command::new("cc");
        for object in request.objects() {
            cmd.arg(object);
        }
        cmd.arg("-o").arg(request.output());
        cmd
    }
}

#[cfg(windows)]
mod platform {
    use super::LinkRequest;
    use std::process::Command;

    pub fn linker_command(request: &LinkRequest) -> Command {
        let mut cmd = Command::new("link.exe");
        cmd.arg(format!("/OUT:{}", request.output().display()));
        for object in request.objects() {
            cmd.arg(object);
        }
        cmd
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn rejects_empty_object_list() {
        let result = LinkRequest::new(Vec::new(), PathBuf::from("xb"));
        assert!(matches!(result, Err(LinkError::EmptyObjects)));
    }

    #[test]
    fn builds_request_when_object_exists_in_request() {
        let request = LinkRequest::new(vec![PathBuf::from("main.o")], PathBuf::from("xb")).unwrap();
        assert_eq!(request.objects(), &[PathBuf::from("main.o")]);
    }
}
